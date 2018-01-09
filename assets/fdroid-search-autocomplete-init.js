(function() {

    var elements = document.getElementsByClassName('search-input-wrapper');
    for (var i = 0; i < elements.length; i ++) {
        var element = elements[i];

        var searchId = element.getAttribute('data-search-id');
        var baseurl = element.getAttribute('data-baseurl');
        var fdroidRepo = element.getAttribute('data-fdroid-repo');
        var repoTimestamp = element.getAttribute('data-repo-timestamp');

        FDroid.Search.addAutocomplete(
            element,
            document.getElementById('search-result-template-' + searchId),
            baseurl,
            fdroidRepo,
            repoTimestamp
        );
    }
})();