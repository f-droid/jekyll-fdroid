/*
**  After the HTML-Document got loaded, the Function is called:
**
*/
document.onload(function () {
    
    // Registering the Listener of the Search-Plugin:
    FDroid.Search.addFullSearch(
        document.getElementById('search-input-{{ search_id }}'),
        document.getElementById('search-result-template-{{ search_id }}'),
        '{{ empty_search_id }}', // Don't get this element yet, because it may not be part of the DOM yet (if it is below this in the resulting HTML)
        '{{ site.baseurl }}',
        '{{ site.fdroid-repo }}',
        '{{ repo_timestamp }}'
    );
});