var tutorial;
function tutor(data) {
    this.chapter = data.chapter;
    this.steps = data.steps;
    this.step = 1;
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
    $('#stdout')
        .append(
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
    if ( new RegExp(this.steps[this.step-1].match).exec(input) ) {
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

        $('#stdout').append(
            $('<h1>')
                .text("Tutorial chapter " + id + ": " + data.title)
                .fadeIn('slow', function () { tutorial.show_step(1) })
        );
    });
}

function load_tutorial_index() {
    $("#feedback").fadeOut('slow', function () {
        $.getJSON('js/chapters/index.js', function (data) {
            $("#feedback")
                .html($("<h1>").text(data.title))
                .append($("<p>").text('Type "help" to display the help message again.'));

            var list = $("<ul id=\"chapters\">");
            $("#feedback").append(list);
            for (var x in data.info) {
                var item = $("<li>").text(data.info[x].title);
                list.append(item);
                (function (item) {
                    if (data.info[x].details) {
                        var details = $("<ul>");
                        item.append(details);
                        for (var y in data.info[x].details) {
                            details.append($("<li>").text(data.info[x].details[y]));
                        }
                    }
                })(item);
            }
        });
        $("#feedback").fadeIn("slow");
    });
}

