(function() {

    /**
     * Loads an index.json file built by jekyll-fdroid via AJAX. Once loaded, it is passed to buildIndex()
     * which will construct the search index and also add the search widget to the DOM.
     */
    function loadIndex(config) {

        var http = new XMLHttpRequest();
        http.onreadystatechange = function () {
            if (http.readyState === XMLHttpRequest.DONE && http.status === 200) {
                var data = JSON.parse(http.responseText);
                buildIndex(config, data.docs, data.index);
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
                pkg.icon_url = config.fdroidRepo + '/icons/' + pkg.icon;
            }
        }

        index = lunr.Index.load(index);

        var autocomplete = setupSearch(config);
        autocomplete.input.oninput = function() {
            performSearch(autocomplete, index, packages, autocomplete.input.value);
        };
    }

    /**
     * Construct the Awesomplete based on the a dynamically created input element. It is configured to render the Mustache
     * template available in the #search-result-template script element.
     * @returns {Awesomplete}
     */
    function setupSearch(config) {
        var template = config.templateElement.innerHTML;
        Mustache.parse(template);

        var searchInput = document.createElement('input');
        searchInput.type = "text";

        config.element.appendChild(searchInput);

        var autocomplete = new Awesomplete(searchInput, {
            maxItems: 10,
            filter: function() { return true; }, // Don't filter, this is done by lunr.js already.
            item: function(item) {
                var node = document.createElement('li');
                node.innerHTML = Mustache.render(template, item.value);
                return node;
            },
            replace: function(item) {
                // This isn't actualy required, because we redirect the browser once the user selects an option.
                // However without it, there will be a brief period while loading the next page that it looks weird.
                this.input.value = item.value.name;
            }
        });

        searchInput.addEventListener('awesomplete-selectcomplete', function(event) {
            document.location = config.baseurl + '/packages/' + event.text.value.packageName + '/';
        });

        return autocomplete;
    }

    /**
     * Executed each time the user enteres some new text in the search input.
     * Uses the lunr.js index to perform a search, then update the Awesomplete input with the search results. The
     * search which is performed is a wildcard search.
     * @param {Awesomplete} autocomplete
     * @param {lunr.Index} index
     * @param {Object[]} packages
     * @param {string} terms
     */
    function performSearch(autocomplete, index, packages, terms) {
        // For performance reasons, don't try and search with less than three characters. There is a noticibly longer
        // search time when searching for 1 or 2 string terms.
        if (terms == null || terms.length < 3) {
            return;
        }

        autocomplete.list = index.search(terms + "*").map(function(item) {
            return packages[item.ref];
        });
    }

    window.FDroid = window.FDroid || {};
    window.FDroid.Search = window.FDroid.Search || {};

    /**
     * @param element DOM Element where the autocomplete is to be appended to.
     * @param templateElement DOM Element for the script tag (with type "x-tmpl-mustache") where the Mustache.js
     *                        template lives.
     * @param baseurl The site.baseurl variable from Jekyll.
     * @param fdroidRepo The site.fdroid-repo variable from Jekyll.
     */
    window.FDroid.Search.addAutocomplete = function(element, templateElement, baseurl, fdroidRepo) {
        loadIndex({
            element: element,
            templateElement: templateElement,
            baseurl: baseurl,
            fdroidRepo: fdroidRepo
        });
    };

})();
