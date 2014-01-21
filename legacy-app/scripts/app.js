(function() {
  var $isotope, drawPlots, formatNum, h, initIsotope, makePlot, margin, numActive, reIsotope, removePlots, tooltip, w, x, xAxis, y, yAxis;

  margin = {
    t: 20,
    r: 30,
    b: 20,
    l: 40
  };

  w = 260 - margin.l - margin.r;

  h = 140 - margin.t - margin.b;

  x = d3.scale.ordinal().rangeRoundBands([0, w], 0.1).domain(d3.range(2000, 2013));

  y = d3.scale.linear().range([h, 0]);

  formatNum = d3.format(',');

  numActive = 0;

  $isotope = $('#isotope-content');

  tooltip = d3.select('#isotope-content').append('div').attr('class', 'tooltip');

  xAxis = d3.svg.axis().orient('bottom').tickFormat(function(d, i) {
    if (i % 3 === 0) {
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

  initIsotope = function() {
    return $isotope.isotope({
      itemSelector: '.destination',
      layoutMode: 'fitRows',
      getSortData: {
        applicants: function($el) {
          return $el[0].__data__.applicants;
        },
        name: function($el) {
          return $el[0].__data__.destination;
        },
        per1k: function($el) {
          return $el[0].__data__.per1k;
        },
        population: function($el) {
          return $el[0].__data__.population;
        }
      }
    });
  };

  $('.isotope-filter-div').click(function() {
    var $selector;
    $('.isotope-filter-div').removeClass('active');
    $(this).addClass('active');
    $selector = $(this).find('a').attr('data-filter');
    return $isotope.isotope({
      filter: $selector
    });
  });

  $('.isotope-sorter-div').click(function() {
    var ascending, sorter;
    $('.isotope-sorter-div').removeClass('active');
    $(this).addClass('active');
    sorter = $(this).find('a').attr('href').slice(1);
    ascending = sorter === 'name' ? true : false;
    $isotope.isotope({
      sortBy: sorter,
      sortAscending: ascending
    });
    return false;
  });

  reIsotope = function(el) {
    var origOffset;
    origOffset = el.parent().offset().top;
    return $isotope.isotope('reLayout', function() {
      if (Math.abs(el.parent().offset().top - origOffset) > (window.innerHeight * 2 / 3)) {
        return $('html, body').animate({
          scrollTop: el.parent().offset().top - 70
        }, 700);
      }
    });
  };

  drawPlots = function() {
    var $selection, $self, activeClassNum, dataName;
    numActive++;
    $self = $(this);
    dataName = $self.attr('data-name');
    activeClassNum = (numActive % 6).toString();
    $selection = $('div[data-name=' + dataName + ']');
    d3.selectAll('[data-name=' + dataName + ']').classed('active' + activeClassNum, true).each(function() {
      var d3el;
      d3el = d3.select(this);
      if (d3el[0][0].__data__ && !d3el[0][0].__drawn__) {
        d3el.call(makePlot);
        return d3el[0][0].__drawn__ = true;
      }
    });
    $selection.find('.plotDiv').slideDown();
    return $(":animated").promise().done(function() {
      reIsotope($self);
      return $selection.unbind('click').click(removePlots);
    });
  };

  removePlots = function() {
    var $selection, $self, dataName;
    $self = $(this);
    numActive--;
    dataName = d3.select(this).attr('data-name');
    $selection = $('div[data-name=' + dataName + ']');
    $selection.find('.plotDiv').slideUp();
    return $(":animated").promise().done(function() {
      $selection.removeClass(function(i, css) {
        return css.match(/active\d/g, '')[0];
      });
      reIsotope($self);
      return $selection.unbind('click').click(drawPlots);
    });
  };

  makePlot = function(self) {
    var data, plotDiv, plotRects, plotRectsJoin, plotSvg, yearData;
    data = self[0][0].__data__;
    yearData = data.years;
    plotDiv = self.append('div').attr('class', 'plotDiv');
    plotSvg = plotDiv.append('svg').attr({
      width: w + margin.l + margin.r,
      height: h + margin.t + margin.b
    }).append('g').attr('class', 'plotG').attr('transform', 'translate(' + [margin.l, margin.t] + ')');
    y.domain([
      0, d3.max(yearData, function(d) {
        return Math.max(0.5, d.applicantsPer1k);
      })
    ]);
    plotSvg.append('g').attr('class', 'x axis').attr('transform', 'translate(' + [0, h] + ')').call(xAxis);
    plotSvg.append('g').attr('class', 'y axis').call(yAxis);
    plotRectsJoin = plotSvg.selectAll('.plotRect').data(yearData);
    return plotRects = plotRectsJoin.enter().append('rect').attr({
      "class": 'plotRect',
      width: x.rangeBand(),
      height: function(d) {
        return h - y(d.applicantsPer1k);
      },
      x: function(d) {
        return x(d.year);
      },
      y: function(d) {
        return y(d.applicantsPer1k);
      }
    }).on('mouseover', function(d) {
      tooltip.html(d3.round(d.applicantsPer1k, 2) + ' applicants per 1,000 people in ' + d.year);
      return tooltip.style('visibility', 'visible');
    }).on('mousemove', function() {
      return tooltip.style({
        top: (d3.event.pageY - 110) + 'px',
        left: (d3.event.pageX - 45) + 'px'
      });
    }).on('mouseout', function() {
      return tooltip.style('visibility', 'hidden');
    });
  };

  d3.json('/data/nested.json', function(json) {
    (function() {
      var countryDivs, countryJoin, data, originDivs, originJoin;
      data = json.sort(function(a, b) {
        return b.destination - a.destination;
      });
      countryJoin = d3.select('#isotope-content').selectAll('.destination').data(data, function(d) {
        return d.destination;
      });
      countryDivs = countryJoin.enter().append('div').attr('class', function(d) {
        return 'destination ' + d.region.replace(/(\s|\(|\))/g, '') + ' ' + d.continent.replace(/(\s|\(|\))/g, '');
      }).html(function(d) {
        return '<h2>' + d.destination + '</h2><p class="overview-p"><strong>' + formatNum(d.applicants) + '</strong> asylum seekers since 2000, or <strong>' + d3.round(d.per1k, 2) + '</strong> for every 1,000 people.</p>' + '\
        <div class="origin-table-header"><span class="origin-name">Origin</span><span class="origin-num">No.</span></div>';
      });
      originJoin = countryDivs.selectAll('.origin').data(function(d) {
        return d.origins;
      });
      return originDivs = originJoin.enter().append('div').attr('class', 'origin').attr('data-name', function(d) {
        return d.origin.replace(/(\s|\(|\)|')/g, '');
      }).html(function(d, i) {
        return '<span class="origin-name"><h4>#' + (i + 1) + ': ' + d.origin + '</h4></span><span class="origin-num"> ' + formatNum(d.applicants) + '</span>';
      });
    })();
    $('.origin, .origin-div').on('click', drawPlots);
    return initIsotope();
  });

  $('.dropdown-menu li .interaction-div').click(function() {
    var selText;
    selText = $(this).text();
    return $(this).parents('.btn-group').find('.dropdown-toggle').html(selText + ' <span class="caret"></span>');
  });

}).call(this);

(function() {


}).call(this);
