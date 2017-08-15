(function() {

    /**
     * Loads an index.json file built by jekyll-fdroid via AJAX. Once loaded, it is passed to buildIndex()
     * which will construct the search index and also add the search widget to the DOM.
     * 
     * Note that both the autocomplete sidebar and also the full search widget both require index
     * data to operate. This caches the results in the `indexData` variable, and ensures that the
     * actual network call is only performed once.
     */
    function loadIndex(config) {
        var existingData = window.FDroid.Search.Net.indexData;
        if (existingData !== null) {
            buildIndex(config, existingData.docs, existingData.index);
            return;
        }

        window.FDroid.Search.Net.indexLoadedCallbacks.push(function(docs, index) {
            buildIndex(config, docs, index);
        });

        if (window.FDroid.Search.Net.isLoadingIndex) {
            return;
        }

        window.FDroid.Search.Net.isLoadingIndex = true;
        var http = new XMLHttpRequest();
        http.onreadystatechange = function () {
            if (http.readyState === XMLHttpRequest.DONE && http.status === 200) {
                var data = JSON.parse(http.responseText);
                for (var i = 0; i < window.FDroid.Search.Net.indexLoadedCallbacks.length; i ++) {
                    window.FDroid.Search.Net.indexLoadedCallbacks[i](data.docs, data.index);
                }
                window.FDroid.Search.Net.indexData = data;
                window.FDroid.Search.Net.isLoadingIndex = false;
            }
        };

        http.open('GET', config.baseurl + '/js/index.json', true);
        http.send();

    }

    /**
     * Iterate over the packages provided, and for each ensure the name + summary is indexed. Theoretically we could
     * of course index the description too, but given the rate at which this would increase the index size, it is to
     * be avoided. Note that lunr.js allows us to prebuild the index to save time, but this may not be a good idea
     * because:
     *  * We still need the original documents, and so we will end up making two web requests (one for documents
     *    and one for the index).
     */
    function buildIndex(config, packages, index) {
        for (var packageId in packages) {
            if (packages.hasOwnProperty(packageId)) {
                var pkg = packages[packageId];
                pkg.icon_url = config.fdroidRepo + '/' + pkg.icon;
            }
        }

        index = lunr.Index.load(index);

        config.onLoad(config, packages, index)
    }

    /**
     * Anything after the "#q=" in the URL is used for the intial search terms when showing a full search.
     * The reason for #q= is to be forwards compatible with an arbitrary number of arguments in the future,
     * such as "#q=F-Droid&page=2"
     */
    function getInitialSearchTerms() {
        return window.location.hash.substring(3)
    }

    /**
     * Helper method to ensure that the search input for both full search and autocomplete are similar.
     */
    function createSearchInput() {
        var searchInput = document.createElement('input');
        searchInput.type = "text";
        searchInput.className = "search-input";
        return searchInput
    }

    function handleFullSearchResults(config, packages, index) {
        var searchInput = createSearchInput();
        searchInput.value = getInitialSearchTerms();
        config.element.appendChild(searchInput);

        var resultsContainer = document.createElement('ul')
        resultsContainer.className = "results";
        config.element.appendChild(resultsContainer);

        var emptySearchElement = config.emptySearchElement;
        var defaultEmptySearchElementDisplay = emptySearchElement == null ? null : emptySearchElement.style.display;

        var showResults = function() {
            // Use loop instead of innerHTML = '' for performance (https://stackoverflow.com/a/3955238)
            while (resultsContainer.firstChild) {
                resultsContainer.removeChild(resultsContainer.firstChild);
            }

            var results = performSearch(index, packages, searchInput.value);

            if (results == null) {
                if (emptySearchElement != null) {
                   emptySearchElement.style.display = defaultEmptySearchElementDisplay;
                }
            } else {
                emptySearchElement.style.display = 'none';
                results.forEach(function(item) {
                    var package = packages[item.ref];
                    var node = document.createElement('li');
                    node.innerHTML = Mustache.render(config.template, package);
                    resultsContainer.appendChild(node);
                })
            }
        }

        // "Debounce" search results so that rapid key presses in succession don't cause a DOM
        // rebuild immediately. Rather, we will wait 300ms of no typing before we go ahead and
        // rebuild the DOM (which has a non-zero cost).
        searchInput.addEventListener('input', debounce(function(event) {
            showResults()
        }, 300));

        // If the search results are prepopulated, show relevant results
        if (searchInput.value != null && searchInput.value.length > 0) {
            showResults()
        }

        // The sidebar can trigger the has to change if it is used on the full search page.
        // Under these circumstances, we should show the relevant results.
        window.onhashchange = function(event) {
            searchInput.value = getInitialSearchTerms();
            showResults();
        };
    }

    function viewPackagePage(config, packageName) {
        document.location = config.baseurl + '/packages/' + packageName + '/';
    }

    /**
     * Construct the Awesomplete based on the a dynamically created input element. It is configured to render the Mustache
     * template available in the #search-result-template script element.
     * @returns {Awesomplete}
     */
    function setupAutocompleteSearch(config) {
        var searchInput = createSearchInput();
        config.element.appendChild(searchInput);

        var autocomplete = new Awesomplete(searchInput, {
            maxItems: 10,
            filter: function() { return true; }, // Don't filter, this is done by lunr.js already.
            item: function(item) {
                var node = document.createElement('li');
                node.innerHTML = Mustache.render(config.template, item.value);
                return node;
            },
            replace: function(item) {
                // This isn't actualy required, because we redirect the browser once the user selects an option.
                // However without it, there will be a brief period while loading the next page that it looks weird.
                this.input.value = item.value.name;
            }
        });

        searchInput.addEventListener('awesomplete-selectcomplete', function(event) {
            viewPackagePage(config, event.text.value.packageName);
        });

        searchInput.onkeypress = function(event) {
            if (event.keyCode == 13) {
                var path = config.baseurl + '/packages'
                if (location.pathname.substr(0, path.length) == path) {
                    location.hash = "q=" + searchInput.value;
                    autocomplete.close();
                } else {
                    document.location = path + '#q=' + searchInput.value;
                }
            }
        };

        return autocomplete;
    }

    function handleAutocompleteResults(config, packages, index) {
        var autocomplete = setupAutocompleteSearch(config);
        autocomplete.input.oninput = function() {
            var results = performSearch(index, packages, autocomplete.input.value);
            if (results !== null) {
                autocomplete.list = results.map(function(item) {
                    return packages[item.ref];
                });
            }
        };
    }

    /**
     * Executed each time the user enteres some new text in the search input.
     * Uses the lunr.js index to perform a search. The search which is performed is a wildcard search.
     * @param {lunr.Index} index
     * @param {Object[]} packages
     * @param {string} terms
     * @return {Object[]|null} Will return null if a the search terms is less than three characters, otherwise an array of results.
     */
    function performSearch(index, packages, terms) {
        // For performance reasons, don't try and search with less than three characters. There is a noticibly longer
        // search time when searching for 1 or 2 string terms.
        if (terms == null || terms.length < 3) {
            return null;
        }

        return index.search(terms + "*")
    }

    // http://beeker.io/jquery-document-ready-equivalent-vanilla-javascript
    var domReady = function(callback) {
        document.readyState === "interactive" || document.readyState === "complete" ? callback() : document.addEventListener("DOMContentLoaded", callback);
    };

    // MIT licensed debounce from https://github.com/jgarber623/javascript-debounce.
    // Used to prevent every single keystroke from a fast typer requiring us to rebuild
    // the DOM of the search results. Instead, it can happen after a pause in typing.
    var debounce = function(callback, delay) {
        var timeout;

        return function() {
            var context = this,
            args = arguments;

            clearTimeout(timeout);

            timeout = setTimeout(function() {
                callback.apply(context, args);
            }, delay);
        };
    };

    window.FDroid = window.FDroid || {};

    /* The `Net` object is to keep track of the network request for index data,
       so that it need only be made once, even if two different search widgets
       request the data. */
    window.FDroid.Search = window.FDroid.Search || {
        Net: {
            indexData: null,
            isLoadingIndex: false,
            indexLoadedCallbacks: [],
        }
    };

    /**
     * @param element DOM Element where the autocomplete is to be appended to.
     * @param templateElement DOM Element for the script tag (with type "x-tmpl-mustache") where the Mustache.js
     *                        template lives.
     * @param baseurl The site.baseurl variable from Jekyll.
     * @param fdroidRepo The site.fdroid-repo variable from Jekyll.
     */
    window.FDroid.Search.addAutocomplete = function(element, templateElement, baseurl, fdroidRepo) {
        var template = templateElement.innerHTML
        Mustache.parse(template)
        loadIndex({
            element: element,
            template: template,
            baseurl: baseurl,
            fdroidRepo: fdroidRepo,
            onLoad: handleAutocompleteResults
        });
    };

    /**
     * @param element DOM Element where the autocomplete is to be appended to.
     * @param templateElement DOM Element for the script tag (with type "x-tmpl-mustache") where the Mustache.js
     *                        template lives.
     * @param emptySearchElement DOM element to show when there is no text in the search box. Can be empty.
     * @param baseurl The site.baseurl variable from Jekyll.
     * @param fdroidRepo The site.fdroid-repo variable from Jekyll.
     */
    window.FDroid.Search.addFullSearch = function(element, templateElement, emptySearchElementId, baseurl, fdroidRepo) {
        var template = templateElement.innerHTML
        Mustache.parse(template)
        
        // Wait for the DOM to load before this runs, because emptySearchElementId may not
        // be part of the DOM when this is called.
        domReady(function() {
            loadIndex({
                element: element,
                emptySearchElement: document.getElementById(emptySearchElementId),
                template: template,
                baseurl: baseurl,
                fdroidRepo: fdroidRepo,
                onLoad: handleFullSearchResults
            });
        });
    };

})();
