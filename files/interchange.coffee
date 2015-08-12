$(document).ready ->
  data = JSON.parse($('#interchange')[0].dataset.data)
  window.Interchange = data
