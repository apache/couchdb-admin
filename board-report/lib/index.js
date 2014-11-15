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
      cheerio = require('cheerio');

const urlTemplate = 'http://markmail.org/search/?q=list%3A' +
  'org.apache.{{listname}}%20date%3A{{date}}';

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

function getMessageCounts (date, cb) {
  const listUrls = lists.map(function (list) {
    return urlTemplate
      .replace('{{date}}', date)
      .replace('{{listname}}', list);
  });

  async.map(listUrls, request, function (err, results) {
    if (err) {
      return cb(err);
    }

    const bodies = results.reduce(function (acc, cur) {
      acc.push(cur.request.req.res.body);
      return acc;
    }, []);

    const res = bodies.map(function (markup) {
      const $ = cheerio.load(markup),
            count = $('#lists .count').text(),
            list = $('#lists a').text().replace('org.apache.couchdb.', '');

      return [list, count];
    });

    return cb(null, res);
  });
}

module.exports = getMessageCounts;
