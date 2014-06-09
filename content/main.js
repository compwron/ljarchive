$.ajax({
    url: '/sidebar/',
    success: function(data) {
        $('div#sidebar').html(data);
    }
});
