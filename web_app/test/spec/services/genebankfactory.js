'use strict';

describe('Service: GenebankFactory', function () {

  // load the service's module
  beforeEach(module('genebanksDistributionApp'));

  // instantiate service
  var GenebankFactory;
  beforeEach(inject(function (_GenebankFactory_) {
    GenebankFactory = _GenebankFactory_;
  }));

  it('should do something', function () {
    expect(!!GenebankFactory).toBe(true);
  });

});
