margin = {t: 20, r: 30, b: 20, l:40}
w = 250 - margin.l - margin.r
h = 140 - margin.t - margin.b
x = d3.scale.ordinal().rangeRoundBands([0, w], 0.1)
y = d3.scale.linear().range([h, 0])
formatNum = d3.format(',')
numActive = 0
$main = $('#main')

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

initIsotope = () ->
  $main.isotope({
    itemSelector: '.destination',
    layoutMode: 'fitRows'
  })

reIsotope = (callback) ->
  $main.isotope('reLayout', callback)


# draw all plots for that country
revealPlots = () ->
  numActive++
  $self = $(this)
  origOffset = $self.offset().top - $(document).scrollTop()
  console.log origOffset

  activeClassNum = (numActive % 6).toString()
  dataName = $(this).attr('data-name')
  $selection = $('div[data-name=' + dataName + ']')

  $selection.addClass('active' + activeClassNum)
  $selection.find('.plotDiv').slideDown()

  $(":animated").promise().done(() ->
    reIsotope(() -> $('html, body').animate({
      scrollTop: $self.offset().top - 100
    }, 700))
    $selection.unbind('click').click(hidePlots)
  )
  
# func to un-transition and delete a plot
hidePlots = () ->
  dataName = $(this).attr('data-name')
  $selection = $('[data-name=' + dataName + ']')

  $selection.find('.plotDiv').slideUp()

  $(":animated").promise().done(() ->
    $selection.attr('class', 'origin')
    reIsotope()
    $selection.unbind('click').click(revealPlots)
  )


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

  x.domain(yearData.map (d) -> d.year)
  y.domain([0, d3.max(yearData, (d) -> Math.max(0.5, d.applicantsPer1k))])

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
      height: (d) -> h - y(d.applicantsPer1k)
      x: (d) -> x(d.year)
      y: (d) -> y(d.applicantsPer1k)  
    })

# make all the info
d3.json '/data/nested.json', (json) ->
  do ->
    data = json.sort((a, b) -> b.applicants - a.applicants)

    countryJoin = d3.select('#main').selectAll('.destination')
      .data(data, (d) -> d.destination)
    
    countryDivs = countryJoin.enter().append('div')
      .attr('class', 'destination')
      .html((d) -> '<h2>' + d.destination + '</h2><p>' + formatNum(d.applicants) + ' people have sought asylum. That\'s ' + d3.round(d.per1k, 2) + ' asylum seekers for every 1,000 people.</p>')

    originJoin = countryDivs.selectAll('.origin')
      .data((d) -> d.origins)

    originDivs = originJoin.enter().append('div')
      .attr('class', 'origin')
      .attr('data-name', (d) -> d.origin.replace(/(\s|\(|\))/g))
      .html((d, i) -> '<span class="origin-name"><h4>#' + (i + 1) + ': ' + d.origin + '</h4></span><span class="origin-num"> ' + formatNum(d.applicants) + '</span>')
      .each(() -> d3.select(this).call(makePlot))

  $('.origin').on('click', revealPlots)
  initIsotope()
