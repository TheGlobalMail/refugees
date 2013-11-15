margin = {t: 20, r: 30, b: 20, l:40}
w = 250 - margin.l - margin.r
h = 140 - margin.t - margin.b
x = d3.scale.ordinal().rangeRoundBands([0, w], 0.1)
y = d3.scale.linear().range([h, 0])
formatNum = d3.format(',')

xAxis = d3.svg.axis()
  .orient('bottom')
  .tickFormat((d, i) -> if i%2 is 0 then d else '')
  .tickSize(3, 0, 0)
  .scale(x)

yAxis = d3.svg.axis()
  .orient('left')
  .tickFormat((d, i) -> if i%2 is 0 then d else '')
  .tickSize(3, 0, 0)
  .scale(y)

# transition items in sequentially
staggerDelay = (d, i) ->
  i * 70

endAll = (transition, callback) ->
  # some bostock magic for waiting till the end of all transitions before callback
  # https://groups.google.com/forum/#!msg/d3-js/WC_7Xi6VV50/j1HK0vIWI-EJ
  n = 0
  transition.transition().duration(staggerDelay)
    .attr({
      width: x.rangeBand()
      height: 0
      x: (d) -> x(d.year)
      y: (d) -> h
    })
    .style('opacity', 0.2)
    .each(() -> ++n)
    .each('end', () -> if not --n then callback.apply(this.arguments))

# draw all plots for that country
drawPlots = () ->
  dataName = d3.select(this).attr('data-name')
  d3.selectAll('[data-name=' + dataName + ']')
    .classed('active', true)
    .each(() -> d3.select(this).call(makePlot))

# func to un-transition and delete a plot
removePlots = () ->
  dataName = d3.select(this).attr('data-name')
  d3.selectAll('[data-name=' + dataName + ']')
    .classed('active', false)
    .each(() ->
      el = d3.select(this)
      el.selectAll('.plotRect').call(endAll, () ->
        el.select('.plotDiv').remove()
        el.on('click', drawPlots)
      )
    )

# func to draw a plot for a given country
makePlot = (self) ->
  data = self[0][0].__data__
  yearData = data.years

  do ->
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

    x.domain(yearData.map (d) -> d.year)
    y.domain([0, d3.max(yearData, (d) -> d.applicants)])

    plotSvg.append('g')
      .attr('class', 'x axis')
      .attr('transform', 'translate(' + [0, h] + ')')
      .call(xAxis)

    plotSvg.append('g')
      .attr('class', 'y axis')
      .call(yAxis)

    # actual meat of the plot, w/ transitions
    plotRectsJoin = plotSvg.selectAll('.plotRect')
      .data(yearData)

    plotRects = plotRectsJoin.enter().append('rect')
      .attr({
        class: 'plotRect'
        width: x.rangeBand()
        height: 0
        x: (d) -> x(d.year)
        y: (d) -> h
      })
      .style('opacity', 0.2)

    plotRects.transition().duration(400).delay(staggerDelay)
      .attr({
        height: (d) -> h - y(d.applicants)
        x: (d) -> x(d.year)
        y: (d) -> y(d.applicants)  
      })
      .style('opacity', 1.0)
    
    self.on('click', removePlots)

# make all the info
d3.json '/data/nested.json', (json) ->
  data = json.sort((a, b) -> b.total - a.total)

  countryJoin = d3.select('#main').selectAll('.destination')
    .data(data, (d) -> d.destination)
  
  countryDivs = countryJoin.enter().append('div')
    .attr('class', 'destination')
    .html((d) -> '<h2>' + d.destination + '</h2><p>' + formatNum(d.total) + ' people have sought asylum.</p>')

  originJoin = countryDivs.selectAll('.origin')
    .data((d) -> d.origins)

  originDivs = originJoin.enter().append('div')
    .attr('class', 'origin')
    .attr('data-name', (d) -> d.origin.replace(/(\s|\(|\))/g))
    .on('click', drawPlots)
    .html((d, i) -> '<h4>#' + (i + 1) + ': ' + d.origin + '</h4> ' + formatNum(d.total))