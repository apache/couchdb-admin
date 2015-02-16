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

const async = require('async'),
      request = require('request'),
      cheerio = require('cheerio'),
      assert = require('assert'),
      argument = require('./argument.js');

const urlPrefix = 'http://markmail.org/search/?q=list%3Aorg.apache.';
const urlTemplate = urlPrefix + '{{listname}}%20date%3A{{date}}';


const lists = [
  'couchdb-announce',
  'couchdb-user',
  'couchdb-erlang',
  'couchdb-dev',
  'couchdb-commits',
  'couchdb-l10n',
  'couchdb-replication',
  'couchdb-marketing'
];

function api (queryParams, timeframe, cb) {
  assert.ok(queryParams.queryCurr, 'queryParams must be defined');
  assert.ok(queryParams.queryDiff, 'queryParams must be defined');
  assert.equal(typeof timeframe, 'number',
    'timeframe must be a number');
  assert.equal(typeof cb, 'function', 'callback must a a function');

  const listUrlsCurr = getUrls(queryParams.queryCurr),
        listUrlsDiff = getUrls(queryParams.queryDiff);

  async.parallel({
    current: function (cb) {
      getMessageCounts(listUrlsCurr, cb);
    },
    diff: function (cb) {
      getMessageCounts(listUrlsDiff, cb);
    }
  },
  function (err, res) {
    const data = joinDiffWithCurrent(res);
    cb(null, data);
  });
}

function joinDiffWithCurrent (structure) {
  const curr = structure.current,
        diff = structure.diff;

  return curr.reduce(function (acc, el) {
    const name = el[0],
          count = el[1],
          countOld = pick(name, diff);

    acc[name] = {
      curr: normalize(count),
      old: normalize(countOld),
      diff: getDiffString(count, countOld)
    };

    return acc;
  }, {});
}

function pick (element, structure) {
  return structure.reduce(function (acc, row) {
    if (row[0] === element) {
      acc = acc + row[1];
    }
    return acc;
  }, 0);
}

function getDiffString (count, countOld) {
  const result = normalize(count) - normalize(countOld);

  if (result >= 0) {
    return '+' + result;
  }
  return '' + result;
}

function normalize (string) {
  if (!string) {
    string = '0';
  }
  return parseInt(string.replace(',', ''), 10);
}

function getUrls (date) {
  return lists.map(function (list) {
    return urlTemplate
      .replace('{{date}}', date)
      .replace('{{listname}}', list);
  });
}

function requestWithOptions (url, cb) {
  request({
    uri: url,
    pool: {
      maxSockets: Infinity
    }
  }, function (err, res, body) {
    cb(err, [url, body]);
  })
}

function normalizeListName (list) {
  return list.replace(urlPrefix, '').split('%20date')[0];
}

function getMessageCounts (urlList, cb) {
  async.map(urlList, requestWithOptions, function (err, results) {
    if (err) {
      return cb(err);
    }
    const res = results.map(function (element) {
      const $ = cheerio.load(element[1]),
            count = $('#lists .count').text(),
            list = normalizeListName(element[0]);
      return [list, count];
    });

    return cb(null, res);
  });
}

module.exports = api;
