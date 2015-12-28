$(function() {
    console.log('####### JS logging by wg_sneak_agent is on #######');

    window.onerror = function(message, file, line) {
      logError([message, file, line, window.location.pathname]);
    }
});

function logError(details) {
    $.ajax({
        type: 'POST',
        url: '/log_js',
        data: JSON.stringify({context: navigator.userAgent, details: details}),
        contentType: 'application/json'
    });
}
