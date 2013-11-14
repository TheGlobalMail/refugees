(function() {
  var h, makePlot, margin, w, x, xAxis, y, yAxis;

  margin = {
    t: 20,
    r: 30,
    b: 20,
    l: 40
  };

  w = 250 - margin.l - margin.r;

  h = 140 - margin.t - margin.b;

  x = d3.scale.ordinal().rangeRoundBands([0, w], 0.1);

  y = d3.scale.linear().range([h, 0]);

  xAxis = d3.svg.axis().orient('bottom').tickFormat(function(d, i) {
    if (i % 2 === 0) {
      return d;
    } else {
      return '';
    }
  }).tickSize(3, 0, 0).scale(x);

  yAxis = d3.svg.axis().orient('left').tickFormat(function(d, i) {
    if (i % 2 === 0) {
      return d;
    } else {
      return '';
    }
  }).tickSize(3, 0, 0).scale(y);

  makePlot = function(self, data) {
    var el, removePlot, yearData;
    yearData = data.years;
    el = d3.select(self);
    removePlot = function() {
      el.select('.plotDiv').remove();
      return el.on('click', function(d) {
        return makePlot(this, d);
      });
    };
    return (function() {
      var plotDiv, plotRects, plotRectsJoin, plotSvg;
      plotDiv = el.append('div').attr('class', 'plotDiv');
      plotSvg = plotDiv.append('svg').attr({
        width: w + margin.l + margin.r,
        height: h + margin.t + margin.b
      }).append('g').attr('class', 'plotG').attr('transform', 'translate(' + [margin.l, margin.t] + ')');
      x.domain(yearData.map(function(d) {
        return d.year;
      }));
      y.domain([
        0, d3.max(yearData, function(d) {
          return d.applicants;
        })
      ]);
      plotSvg.append('g').attr('class', 'x axis').attr('transform', 'translate(' + [0, h] + ')').call(xAxis);
      plotSvg.append('g').attr('class', 'y axis').call(yAxis);
      plotRectsJoin = plotSvg.selectAll('.plotRect').data(yearData);
      plotRects = plotRectsJoin.enter().append('rect').attr({
        "class": 'plotRect',
        width: x.rangeBand(),
        height: function(d) {
          return h - y(d.applicants);
        },
        x: function(d) {
          return x(d.year);
        },
        y: function(d) {
          return y(d.applicants);
        }
      });
      return el.on('click', function() {
        return removePlot();
      });
    })();
  };

  d3.json('/data/nested.json', function(json) {
    var countryDivs, countryJoin, data, originDivs, originJoin;
    data = json.sort(function(a, b) {
      return b.total - a.total;
    });
    countryJoin = d3.select('#main').selectAll('.destination').data(data, function(d) {
      return d.destination;
    });
    countryDivs = countryJoin.enter().append('div').attr('class', 'destination').html(function(d) {
      return '<h2>' + d.destination + '</h2><p>' + d.total + ' total asylum seekers</p>';
    });
    originJoin = countryDivs.selectAll('.origin').data(function(d) {
      return d.origins;
    });
    return originDivs = originJoin.enter().append('div').attr('class', 'origin').on('click', function(d) {
      return makePlot(this, d);
    }).html(function(d) {
      return '<h4>' + d.origin + '</h4> ' + d.total;
    });
  });

}).call(this);
