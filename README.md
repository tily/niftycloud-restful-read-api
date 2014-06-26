# NIFTYCloud RESTful Read API

## 概要

ニフティクラウドの情報取得系 API を REST っぽく取得できるようにする Sinatra アプリです。

## インストール

        gem install niftycloud-restful-read-api

## 使い方

### コマンドライン

環境変数で認証情報を指定し、niftycloud-restful-read-api コマンドを実行すると、

	$ export ACCESS_KEY_ID=XXXXXXXXXXXXXXXXXXXX
	$ export SECRET_ACCESS_KEY=YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
	$ niftycloud-restful-read-api
	[2014-06-26 01:15:24] INFO  WEBrick 1.3.1
	[2014-06-26 01:15:24] INFO  ruby 2.0.0 (2014-02-24) [universal.x86_64-darwin13]
	== Sinatra/1.4.5 has taken the stage on 4567 for development with backup from WEBrick
	[2014-06-26 01:15:24] INFO  WEBrick::HTTPServer#start: pid=18326 port=4567

http://localhost:4567 からいい感じの JSON が取得できるようになります。

	$ curl -X POST -d "hoge" http://localhost:4567/computing/key_pairs | python -m json.tool
	  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
	                                 Dload  Upload   Total   Spent    Left  Speed
	100   309  100   305  100     4    383      5 --:--:-- --:--:-- --:--:--   383
	[
	    {
	        "keyFingerprint": "1f:e7:bb:c1:c8:a1:32:d1:7d:b5:db:e9:ac:12:37:3a:69:e9:ee:50",
	        "keyName": "JTFJTF"
	    },
	    {
	        "keyFingerprint": "9c:a9:04:9f:e1:8b:36:ca:b3:91:49:6a:fd:d4:47:9f:0f:a5:99:40",
	        "keyName": "default"
	    },
	    {
	        "keyFingerprint": "36:30:be:c6:47:f6:bd:be:38:c9:cd:d1:55:61:aa:0c:c1:ff:a3:00",
	        "keyName": "something"
	    }
	]

### config.ru 

config.ru から require して使うこともできます。

	$ cat config.ru
	require 'niftycloud-restful-read-api'
	run NiftycloudRestfulReadApi
	$ rackup
	[2014-06-26 01:19:34] INFO  WEBrick 1.3.1
	[2014-06-26 01:19:34] INFO  ruby 2.0.0 (2014-02-24) [universal.x86_64-darwin13]
	[2014-06-26 01:19:34] INFO  WEBrick::HTTPServer#start: pid=18378 port=9292

## 対応リソース

### Computing

* /computing/regions
  * リージョン一覧を取得できます
* /computing/instances
  * サーバー一覧を取得できます
* /computing/volumes
  * ディスク一覧を取得できます
* /computing/key_pairs
  * SSH キー一覧を取得できます
* /computing/images
  * イメージ一覧を取得できます
* /computing/load_balancers
  * ロードバランサー一覧を取得できます
* /computing/security_groups
  * ファイアウォール一覧を取得できます
* /computing/ssl_certificates
  * SSL 証明書一覧を取得できます
* /computing/addresses
  * 付替アドレス一覧を取得できます

### RDB

* /rdb/db_instances
  * DB サーバー一覧を取得できます
* /rdb/db_security_groups
  * DB ファイアウォール一覧を取得できます
* /rdb/db_parameter_groups
  * DB パラメーターグループ一覧を取得できます
* /rdb/db_snapshots
  * DB スナップショット一覧を取得できます
* /rdb/db_engine_versions
  * DB エンジンバージョン一覧を取得できます

### MessageQueue

* /mq/queues
  * キュー一覧を取得できます

### DNS

* /dns/zones
  * ゾーン一覧を取得できます

### Storage

* /storage/buckets
  * バケット一覧を取得できます

## TODO

* ニフティクラウド ESS/Automation

## ライセンス

* パブリックドメイン
