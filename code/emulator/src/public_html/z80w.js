$(document).ready(function() {
    window.setInterval(z80wUpdate, 100);
});

function z80wUpdate()
{
    $.getJSON('outputs.json', function(data) {
        var leds = data.leds;
        for (var i = 0; i < 8; i++) {
            if (leds & (1 << i)) {
                $('#led'+i).addClass('led_on');
            } else {
                $('#led'+i).removeClass('led_on');
            }
        }

        for (var i = 0; i < 40; i++) {
            var x = -89, y = -75;
            var ch = data.hd44780[i];
            var h = (ch >> 4) & 0x0f;
            var l = ch & 0x0f;

            x -= (15 * h);
            y -= (22 * l);

            $('#hd44780 #char'+i).css('background-position', x+'px '+y+'px');
        }
    });
}
