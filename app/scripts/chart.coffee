define ['d3', 'jquery', 'isotope'], (d3, $, isotope) ->

  init = () ->
    margin = {t: 5, r: 30, b: 20, l:30}
    w = 240 - margin.l - margin.r
    h = 140 - margin.t - margin.b
    x = d3.scale.ordinal().rangeRoundBands([0, w], 0.1).domain(d3.range(2000, 2013))
    y = d3.scale.linear().range([h, 0])
    formatNum = d3.format(',')
    formatDec = d3.format('r1')
    $isotope = $('#isotope-content')

    tooltip = d3.select('#main')
      .append('div')
      .attr('class', 'tooltip')

    xAxis = d3.svg.axis()
      .orient('bottom')
      .tickValues([2000, 2006, 2012])
      .tickSize(3, 0, 0)
      .scale(x)

    yAxis = d3.svg.axis()
      .orient('left')
      .tickSize(-w, 0, 0)
      .scale(y)

    line = d3.svg.line()
      .interpolate('basis')
      .x((d) -> x(d.year))
      .y((d) -> y(d.applicantsPer10k))

    initIsotope = () ->
      $isotope.isotope({
        itemSelector: '.destination',
        layoutMode: 'fitRows',
        getSortData: {
          applicants: ($el) ->
            $el[0].__data__.applicants
          name: ($el) ->
            $el[0].__data__.destination
          per10k: ($el) ->
            $el[0].__data__.per10k
        },
        sortBy: 'name'
      })

    $('.isotope-filter-div').click (e) ->
      e.preventDefault()
      $('.isotope-filter-div').removeClass('active')
      $(this).addClass('active')
      $('#plot-reset').addClass('active')
      $selector = $(this).find('a').attr('data-filter')
      $isotope.isotope({ filter: $selector })
      selText = $(this).text()
      reIsotope($(this))
      $(this).parents('.dropdown').find('.dropdown-toggle')
        .html('Filter continent: ' + selText + ' <span class="caret"></span>')

    $('.isotope-sorter-div').click (e) ->
      e.preventDefault()
      $('.isotope-sorter-div').removeClass('active')
      $(this).addClass('active')
      $('#plot-reset').addClass('active')
      sorter = $(this).find('a').attr('href').slice(1)
      ascending = if sorter is 'name' then true else false
      $isotope.isotope({ sortBy: sorter, sortAscending: ascending })
      selText = $(this).text()
      $dropdown = $(this).parents('.dropdown')
      $dropdown.find('.dropdown-toggle')
        .html('Sort by: ' + selText + ' <span class="caret"></span>')
      $dropdown.removeClass('open')
      reIsotope($(this))
      false

    $('#legend').popover({
      html: true
      placement: 'bottom'
      content: () ->
        imgPath = $('#img-demo-card').attr('src')
        "<img class=\"demo-card\" src=\"#{imgPath}\">"
    })

    $('#plot-reset').click(() -> resetPlots())

    reIsotope = (el) ->
      origOffset = el.parent().offset().top
      $isotope.isotope 'reLayout', () ->
        if Math.abs(el.parent().offset().top - origOffset) > (window.innerHeight * 2/3)
          $('html, body').animate({
            scrollTop: el.parent().offset().top - 150
          }, 700)
        setTimeout (-> $('svg:visible').attr('transform', 'translate(0,0)')), 400

    # draw all plots for chosen country
    drawPlots = () ->
      $self = $(this)
      dataName = $self.attr('data-name')
      $selection = $('div[data-name=' + dataName + ']')
      $selection.addClass('active')
      $('#plot-reset').addClass('active')

      # give active class to selected things, draw charts
      d3.selectAll('[data-name=' + dataName + ']')
        .each(() ->
          d3el = d3.select(this)
          if d3el[0][0].__data__ and not d3el[0][0].__drawn__
            continent = d3el[0][0].__data__.continent
            d3el.call(makePlot, continent)
            d3el[0][0].__drawn__ = true
        )

      $selection.find('.plotDiv').slideDown()

      # reisotope after slide animation
      $(":animated").promise().done(() ->
        reIsotope($self)
        $selection.unbind('click').click(removePlots)
      )

    highlightPlots = () ->
      $self = $(this)
      dataName = $self.attr('data-name')
      $selection = $('div[data-name=' + dataName + ']')
      $selection.addClass('active-hover')

    removeHighlight = () ->
      $('.origin, .origin-div').removeClass('active-hover')

    # func to un-transition plot and remove active class
    removePlots = () ->
      $self = $(this)
      dataName = d3.select(this).attr('data-name')
      $selection = $('div[data-name=' + dataName + ']')
      $selection.removeClass('active')

      $selection.find('.plotDiv').slideUp()
      $(":animated").promise().done () ->
          
        reIsotope($self)
        $selection.unbind('click').click(drawPlots)

    resetPlots = () ->
      $selection = $('.origin.active')
      $selection.find('.plotDiv').slideUp()

      $(":animated").promise().done () ->
        $isotope.isotope({ sortBy: 'name', sortAscending: true, filter: '*' })
        $selection.unbind('click').click(drawPlots)
        $('#plot-reset').removeClass('active')
        $selection.removeClass('active')
        $('#filter-dropdown').find('.dropdown-toggle')
          .html('Filter continent: All <span class="caret"></span>')
        $('#sorter-dropdown').find('.dropdown-toggle')
          .html('Sort by: Name <span class="caret"></span>')
        $('li.dropdown .active').removeClass('active')

    # func to draw a plot for a given country
    makePlot = (self, continent) ->
      data = self[0][0].__data__
      yearData = data.years

      plotDiv = self.append('div').attr('class', 'plotDiv')

      # draw svg and axes
      plotSvg = plotDiv.append('svg')
        .attr({
          class: 'plotSvg'
          width: w + margin.l + margin.r
          height: h + margin.t + margin.b
        })
      .append('g')
        .attr('class', 'plotG')
        .attr('transform', 'translate(' + [margin.l, margin.t] + ')')

      y.domain([0, d3.max(yearData, (d) -> Math.max(5, d.applicantsPer10k))])
      newTickVals = d3.range(0, y.domain()[1], 2)
      yAxis.tickValues(newTickVals)

      if newTickVals.length > 6
        yAxis.tickFormat((d, i) -> if i%2 is 0 then formatDec(d) else '')
      else
        yAxis.tickFormat(formatDec)

      plotSvg.append('g')
        .attr('class', 'x axis')
        .attr('transform', 'translate(' + [0, h] + ')')
        .call(xAxis)

      plotSvg.append('g')
        .attr('class', 'y axis')
        .call(yAxis)

      plotLines = plotSvg.append('path')
        .datum(yearData)
        .attr({
          class: "plotLine #{continent}"
          d: (d) -> line(d)
        })

    # make all the info
    d3.json '/data/nested.json', (json) ->
      do ->
        data = json.sort((a, b) -> b.destination - a.destination)
        data.forEach (d) ->
          d.per10kStr = if d.per10k > 1 then d3.round(d.per10k, 0) else '<1'

        countryJoin = d3.select('#isotope-content').selectAll('.destination')
          .data(data, (d) -> d.destination)
        
        countryDivs = countryJoin.enter().append('div')
          .attr('class', (d) ->  "destination #{d.continent}")
          .html((d) ->
            region = d.region
            continent = d.continent
            applicants = formatNum(d.applicants)
            return "<div class=\"destination-title #{region} #{continent}\">
            <h2 class=\"destination-name\">#{d.destination}</h2>
            </div>"
          )

        originWrappers = countryDivs.append('div').attr('class', 'origin-wrapper')
          .html("<div class=\"origin-table-header\"><span class=\"origin-name\">Origin</span><span class=\"origin-num\">Total No.</span></div>")

        originJoin = originWrappers.selectAll('.origin')
          .data((d) -> d.origins)

        originDivs = originJoin.enter().append('div')
          .attr('class', (d) -> "origin #{d.continent}")
          .attr('data-name', (d) -> d.origin.replace(/(\s|\(|\)|')/g, ''))
          .html((d, i) -> "<span class=\"origin-name\"><h4>#{d.origin}</h4></span><span class=\"origin-num\">#{formatNum(d.applicants)}</span>")

        originWrappers.append('div')
          .attr('class', 'origin-summary-table')
            .html((d) -> "
              <div class=\"origin-table-header per-tenk\"><span class=\"origin-name\">Per 10,000</span><span class=\"origin-num\">#{d.per10kStr}</span></div>
              <div class=\"origin-table-header per-tenk\"><span class=\"origin-name\">Total Applicants</span><span class=\"origin-num\">#{formatNum(d.applicants)}</span></div>
              ")

      $('.origin, .origin-div').on('click', drawPlots)
      $('.origin, .origin-div').on('mouseover', highlightPlots)
      $('.origin, .origin-div').on('mouseout', removeHighlight)
      $('.loader').fadeOut('slow')
      $('#app-controls-wrapper,#isotope-content').removeClass('loading')
      initIsotope()


  return { init: init }
