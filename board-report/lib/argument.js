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

const moment = require('moment');

exports.prepareQueryParams = prepareQueryParams;
function prepareQueryParams (arg) {
  const startEnd = getStartEndDates(arg, 3);
        startAsString = startEnd[0].format('YYYYMM'),
        diffStartEnd = getStartEndDates(startAsString, 3);

  return {
    queryCurr: formatQuery(startEnd),
    queryDiff: formatQuery(diffStartEnd)
  };
}

exports.validArg = validArg;
function validArg (arg) {
  if (!arg) {
    return false;
  }

  if (arg.length !== 6) {
    return false;
  }

  if (Number.isNaN(+arg)) {
    return false;
  }

  return moment(arg, 'YYYYMM').isValid();
}

exports.getMonthAsWordFromNow = getMonthAsWordFromNow;
function getMonthAsWordFromNow (reportEnd, time) {
  const inter = moment(reportEnd, 'YYYYMM')
    .subtract(time, 'months')
    .format('YYYYMM');

  return moment(inter, 'YYYYMM').format('MMMM');
}

function getMonthAsWord (reportEnd) {
  return moment(reportEnd, 'YYYYMM').format('MMMM');
}

function formatQuery (startEnd) {
  return startEnd[0].format('YYYYMM') + '-' +
    startEnd[1].format('YYYYMM');
}

function getStartEndDates (arg, time) {
  const end = moment(arg, 'YYYYMM'),
        start = moment(arg, 'YYYYMM').subtract(time, 'months');

  return [start, end];
}
