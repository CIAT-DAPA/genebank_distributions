'use strict';

/**
 * @ngdoc function
 * @name genebanksDistributionApp.controller:SankeyCtrl
 * @description
 * # SankeyCtrl
 * Controller of the genebanksDistributionApp
 */
angular.module('genebanksDistributionApp')
  .controller('SankeyCtrl', function (GenebankFactory, config) {
    GenebankFactory.getSankeyCoords().then(function (data) {
      var colors = {
        'australia': '#FF0000',
        'canada': '#EE4000',
        'cgiar': '#8B0000',
        'germany': '#458B00',
        'netherlands': '#cf8730',
        'unitedkingdom': '#8B4513',
        'unitedstatesofamerica': '#1E90FF',
        'in': '#ff0066',
        'fallback': '#9f9fa3'
      };

      var format = d3.format(",.0f");

      var tooltip = d3.select("body")
        .append("div")
        .attr("id", "tooltip")
        .style("position", "absolute")
        .style("z-index", "10")
        .style("visibility", "hidden")
        //.attr("class", "tooltip")
        .text("a simple tooltip");


      drawSankey("#chart_sankey", data);

      function drawSankey(container, data) {
        $(container).html('');
        var chart = d3.select(container).append("svg")
          .attr("height", $(document).height())
          .chart("Sankey.Path");

        chart.name(label)
          .colorNodes(function (name, node) {
            return color(node, 1) || colors.fallback;
          })
          .colorLinks(function (link) {
            return color(link.source, 4) || color(link.target, 1) || colors.fallback;
          })
          .nodeWidth(15)
          .nodePadding(10)
          .spread(true)
          .iterations(0)
          .on('node:click', nodeClick)
          .on('node:mouseover', function (node) {
            console.log(node);
            if (!node.id.endsWith('-gb')) {
              tooltip.style("visibility", "visible");
              tooltip.transition()
                .duration(200)
                .style("opacity", .9);
              tooltip.html('Click on me')
                .style("left", (d3.event.pageX) + 20 + "px")
                .style("top", (d3.event.pageY) + "px");
            }
          })
          .on('node:mouseout', function (link) {
            if (!node.id.endsWith('-gb')) {
              tooltip.transition()
                .duration(500)
                .style("opacity", 0);
              var $tooltip = $("#tooltip");
              $tooltip.empty();
            }
          })
          .on('link:mouseover', function (link) {
            tooltip.style("visibility", "visible");
            tooltip.transition()
              .duration(200)
              .style("opacity", .9);
            tooltip.html(format(link.value))
              .style("left", (d3.event.pageX) + 20 + "px")
              .style("top", (d3.event.pageY) + "px");
          })
          .on('link:mouseout', function (link) {
            tooltip.transition()
              .duration(500)
              .style("opacity", 0);
            var $tooltip = $("#tooltip");
            $tooltip.empty();
          })
          .draw(data);
      }

      function nodeClick(node) {
        var newSankey = [];
        if (config.sankey_depth == 1) {
          newSankey = data.subSankey.filter(function (item) {
            return item.id[0] === node.id;
          });
          newSankey = newSankey[0].sankey;
          config.sankey_depth = 2;
        }
        else {
          newSankey = data;
          config.sankey_depth = 1;
        }
        drawSankey("#chart_sankey", newSankey);
      }

      function label(node) {
        return node.name.replace(/\s*\(.*?\)$/, '');
      }
      function color(node, depth) {
        var id = node.id.replace(/(-gb)?(_\d+)?$/, '');
        if (colors[id]) {
          return colors[id];
        }
        //else if (node.id.endsWith('_in') || node.id.endsWith('_out')) {
        else if (node.id.endsWith('_in')) {
          return colors['in'];
        }
        else if (depth < 0 && node.targetLinks && node.targetLinks.length == 1) {
          return color(node.targetLinks[0].source, depth - 1);
        }
        else {
          return null;
        }
      }
    });

  });
