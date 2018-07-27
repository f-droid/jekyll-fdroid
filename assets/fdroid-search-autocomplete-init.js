//@license magnet:?xt=urn:btih:0b31508aeb0634b347b8270c7bee4d411b5d4109&dn=agpl-3.0.txt AGPL-v3
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
// @license-end
