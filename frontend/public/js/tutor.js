var tutorial;
function tutor(data) {
    this.chapter = data.chapter;
    this.steps = data.steps;
    this.step = 1;
    this.cur_step = '';
}
tutor.fn = tutor.prototype;
tutor.fn.next = function () {
    if ( this.step < this.steps.length ) {
        this.show_step(++this.step);
    }
    else {
        this.next_chapter();
    }
}
tutor.fn.prev = function () {
    if ( this.step > 1 ) {
        this.show_step(--this.step);
    }
}
tutor.fn.show_step = function (step) {
    var data = this.steps[step-1];
    this.cur_step
        .html(
            $('<p class="step">').text(
                '(' + (this.step) + ' of ' + this.steps.length + ') ' + data.explanation
            )
        ).append(
            $('<p class="example">')
                .text('Example: ')
                .append( $('<samp>').html(data.example + "&nbsp;&nbsp;&crarr;") )
        );
}
tutor.fn.do_step = function (input) {
    var regex = this.steps[this.step-1].match;
    if ( regex instanceof Array ) {
        regex = regex.join('\\s*');
    }

    if ( new RegExp(regex).exec(input) ) {
        this.next();
    }
}
tutor.fn.next_chapter = function () {
    load_chapter(parseInt(this.chapter) + 1);
}

function load_chapter(id) {
    $.getJSON('js/chapters/'+id+'.js', function (data) {
        data.chapter = id;
        tutorial = new tutor(data);

        tutorial.cur_step = $("<div>");
        tutorial.show_step(1);

        $('#feedback').fadeOut('slow', function () {
            $(this)
                .html($('<h1>').text("Tutorial chapter " + id + ": " + data.title))
                .append(tutorial.cur_step)
                .fadeIn('slow');
        });
    });
}

function load_tutorial_index() {
    $("#feedback").fadeOut('slow', function () {
        $.getJSON('js/chapters/index.js', function (data) {
            var list = $("<ul id=\"chapters\">");

            for (var x in data.info) {
                var item = $("<li>").text(data.info[x].title);
                (function (item) {
                    if (data.info[x].details) {
                        var details = $("<ul>");
                        item.append(details);
                        for (var y in data.info[x].details) {
                            details.append($("<li>").text(data.info[x].details[y]));
                        }
                    }
                })(item);
                list.append(item);
            }

            $("#feedback")
                .html($("<h1>").text(data.title))
                .append($("<p>").text('Type "help" to display the help message again.'))
                .append(list);
        });
        $("#feedback").fadeIn("slow");
    });
}

