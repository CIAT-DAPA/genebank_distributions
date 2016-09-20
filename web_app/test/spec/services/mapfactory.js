'use strict';

describe('Service: MapFactory', function () {

  // load the service's module
  beforeEach(module('genebanksDistributionApp'));

  // instantiate service
  var MapFactory;
  beforeEach(inject(function (_MapFactory_) {
    MapFactory = _MapFactory_;
  }));

  it('should do something', function () {
    expect(!!MapFactory).toBe(true);
  });

});
