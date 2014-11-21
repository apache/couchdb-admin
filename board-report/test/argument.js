// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License. You may obtain a copy of
// the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations under
// the License.

const assert = require('assert'),
      argument = require('../lib/argument.js');

describe('arguments', function () {

  it('validates arguments', function () {
    assert.ok(argument.validArg('201401'));
    assert.equal(argument.validArg('2ente'), false);
    assert.equal(argument.validArg('2014123'), false);
  });

   it('has a method for getting names of months', function () {
    assert.equal(argument.getMonthAsWord('201401'), 'January');
    assert.equal(argument.getMonthAsWord('201412'), 'December');
  });

  it('prepares query parameters', function () {
    const queryParams = argument.prepareQueryParams('201411');

    assert.equal(queryParams.queryCurr, '201408-201411');
    assert.equal(queryParams.queryDiff, '201405-201408');
  });

  it('prepares urls for the current and the diff', function () {
    const queryParams = argument.prepareQueryParams('201411');

    assert.equal(queryParams.queryCurr, '201408-201411');
    assert.equal(queryParams.queryDiff, '201405-201408');
  });
});
