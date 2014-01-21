define ['d3', 'jquery', 'isotope'], (d3, $, isotope) ->

  init = () ->
    margin = {t: 20, r: 30, b: 20, l:40}
    w = 220 - margin.l - margin.r
    h = 140 - margin.t - margin.b
    x = d3.scale.ordinal().rangeRoundBands([0, w], 0.1).domain(d3.range(2000, 2013))
    y = d3.scale.linear().range([h, 0])
    formatNum = d3.format(',')
    formatDec = d3.format('r1')
    numActive = 0
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
      .y((d) -> y(d.applicantsPer1k))

    initIsotope = () ->
      $isotope.isotope({
        itemSelector: '.destination',
        layoutMode: 'fitRows',
        getSortData: {
          applicants: ($el) ->
            $el[0].__data__.applicants
          name: ($el) ->
            $el[0].__data__.destination
          per1k: ($el) ->
            $el[0].__data__.per1k
          population: ($el) ->
            $el[0].__data__.population
        }
      })

    $('.isotope-filter-div').click(() ->
      $('.isotope-filter-div').removeClass('active')
      $(this).addClass('active')
      $selector = $(this).find('a').attr('data-filter')
      $isotope.isotope({ filter: $selector })
    )

    $('.isotope-sorter-div').click(() ->
      $('.isotope-sorter-div').removeClass('active')
      $(this).addClass('active')
      sorter = $(this).find('a').attr('href').slice(1)
      ascending = if sorter is 'name' then true else false
      $isotope.isotope({ sortBy: sorter, sortAscending: ascending })
      false
    )

    reIsotope = (el) ->
      origOffset = el.parent().offset().top
      $isotope.isotope('reLayout', () ->
        if Math.abs(el.parent().offset().top - origOffset) > (window.innerHeight * 2/3)
          $('html, body').animate({
            scrollTop: el.parent().offset().top - 70
          }, 700))

    # draw all plots for chosen country
    drawPlots = () ->
      numActive++
      $self = $(this)
      dataName = $self.attr('data-name')
      activeClassNum = (numActive % 6).toString()
      $selection = $('div[data-name=' + dataName + ']')

      # give active class to selected things, draw charts
      d3.selectAll('[data-name=' + dataName + ']')
        .classed('active' + activeClassNum, true)
        .each(() ->
          d3el = d3.select(this)
          if d3el[0][0].__data__ and not d3el[0][0].__drawn__
            d3el.call(makePlot)
            d3el[0][0].__drawn__ = true
        )

      $selection.find('.plotDiv').slideDown()

      # reisotope after slide animation
      $(":animated").promise().done(() ->
        reIsotope($self)
        $selection.unbind('click').click(removePlots)
      )

    # func to un-transition plot and remove active class
    removePlots = () ->
      $self = $(this)
      numActive--
      dataName = d3.select(this).attr('data-name')
      $selection = $('div[data-name=' + dataName + ']')

      $selection.find('.plotDiv').slideUp()
      $(":animated").promise().done () ->
        $selection.removeClass (i, css) ->
          css.match(/active\d/g, '')[0]
          
        reIsotope($self)
        $selection.unbind('click').click(drawPlots)

    # func to draw a plot for a given country
    makePlot = (self) ->
      data = self[0][0].__data__
      yearData = data.years

      plotDiv = self.append('div').attr('class', 'plotDiv')

      # draw svg and axes
      plotSvg = plotDiv.append('svg')
        .attr({
          width: w + margin.l + margin.r
          height: h + margin.t + margin.b
        })
      .append('g')
        .attr('class', 'plotG')
        .attr('transform', 'translate(' + [margin.l, margin.t] + ')')

      y.domain([0, d3.max(yearData, (d) -> Math.max(0.5, d.applicantsPer1k))])
      newTickVals = d3.range(0, y.domain()[1], 0.2)
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
          class: 'plotLine'
          d: (d) -> line(d)
        })

    # make all the info
    d3.json '/data/nested.json', (json) ->
      do ->
        data = json.sort((a, b) -> b.destination - a.destination)

        countryJoin = d3.select('#isotope-content').selectAll('.destination')
          .data(data, (d) -> d.destination)
        
        countryDivs = countryJoin.enter().append('div')
          .attr('class', (d) -> 'destination ' + d.region.replace(/(\s|\(|\))/g, '') + ' ' + d.continent.replace(/(\s|\(|\))/g, ''))
          .html((d) -> '<h2 class="destination-name">' + d.destination + '</h2><p class="overview-p"><strong>' + formatNum(d.applicants) + '</strong> asylum seekers since 2000, or <strong>' + d3.round(d.per1k, 2) + '</strong> for every 1,000 people.</p>' + '
            <div class="origin-table-header"><span class="origin-name">Origin</span><span class="origin-num">No.</span></div>'
          )

        originJoin = countryDivs.selectAll('.origin')
          .data((d) -> d.origins)

        originDivs = originJoin.enter().append('div')
          .attr('class', 'origin')
          .attr('data-name', (d) -> d.origin.replace(/(\s|\(|\)|')/g, ''))
          .html((d, i) -> '<span class="origin-name"><h4>#' + (i + 1) + ': ' + d.origin + '</h4></span><span class="origin-num"> ' + formatNum(d.applicants) + '</span>')

      $('.origin, .origin-div').on('click', drawPlots)

      initIsotope()

    $('.interaction-div a').click () ->
      selText = $(this).text()
      $(this).parents('.dropdown').find('.dropdown-toggle')
        .html(selText + ' <span class="caret"></span>');

  return { init: init }
