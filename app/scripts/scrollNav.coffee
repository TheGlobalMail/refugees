define ['jquery', 'lodash'], ($, _) ->
  $nav = $('#app-controls')
  navWrapper = document.getElementById('app-controls-wrapper')

  scrollNav = () ->
    navOffset = navWrapper.getBoundingClientRect().top
    if navOffset <= 50
      $nav.addClass('fixed')
    else
      $nav.removeClass('fixed')

  $(window.document).bind('scroll', _.throttle(scrollNav, 50) )
