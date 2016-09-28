'use strict';

/**
 * @ngdoc overview
 * @name genebanksDistributionApp
 * @description
 * # genebanksDistributionApp
 *
 * Main module of the application.
 */
angular
  .module('genebanksDistributionApp',  ['swipe','snapscroll','uiGmapgoogle-maps'])
  .value('config',{
      data_genebanks: 'data/genebanks.json',
      sankey_depth:1,
      genebanks_map: 'data/map_genebanks.json'
  });
