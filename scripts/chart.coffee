margin = {t: 20, r: 30, b: 20, l:40}
w = 250 - margin.l - margin.r
h = 140 - margin.t - margin.b
x = d3.scale.ordinal().rangeRoundBands([0, w], 0.1)
y = d3.scale.linear().range([h, 0])

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

makePlot = (self, data) ->
  yearData = data.years
  el = d3.select(self)

  removePlot = () ->
    el.select('.plotDiv').remove()
    el.on('click', (d) -> makePlot(this, d))

  do ->
    plotDiv = el.append('div').attr('class', 'plotDiv')

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

    plotRectsJoin = plotSvg.selectAll('.plotRect')
      .data(yearData)

    plotRects = plotRectsJoin.enter().append('rect')
      .attr({
        class: 'plotRect'
        width: x.rangeBand()
        height: (d) -> h - y(d.applicants)
        x: (d) -> x(d.year)
        y: (d) -> y(d.applicants)  
      })
    
    el.on('click', () -> removePlot())

d3.json '/data/nested.json', (json) ->
  data = json.sort((a, b) -> b.total - a.total)

  countryJoin = d3.select('#main').selectAll('.destination')
    .data(data, (d) -> d.destination)
  
  countryDivs = countryJoin.enter().append('div')
    .attr('class', 'destination')
    .html((d) -> '<h2>' + d.destination + '</h2><p>' + d.total + ' total asylum seekers</p>')

  originJoin = countryDivs.selectAll('.origin')
    .data((d) -> d.origins)

  originDivs = originJoin.enter().append('div').attr('class', 'origin')
    .on('click', (d) -> makePlot(this, d))
    .html((d) -> '<h4>' + d.origin + '</h4> ' + d.total)