window.BENCHMARK_DATA = {
  "lastUpdate": 1783459475259,
  "repoUrl": "https://github.com/jane-street-immersion-program/jsip-exchange",
  "entries": {
    "Order book benchmark": [
      {
        "commit": {
          "author": {
            "email": "abauer@janestreet.com",
            "name": "Aaron Bauer",
            "username": "awilliambauer"
          },
          "committer": {
            "email": "abauer@janestreet.com",
            "name": "Aaron Bauer",
            "username": "awilliambauer"
          },
          "distinct": true,
          "id": "9793ef0599b0ad3ae76985f41377bfcd0ca61334",
          "message": "clean up opam download cache in docker image to keep size down",
          "timestamp": "2026-06-13T15:46:15-04:00",
          "tree_id": "1a13156a3e36e126f511d215e2ad445563086b5a",
          "url": "https://github.com/jane-street-immersion-program/jsip-exchange/commit/9793ef0599b0ad3ae76985f41377bfcd0ca61334"
        },
        "date": 1781384168388,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 24.169306513329683,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 24.596558570186897,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 24.858382344185056,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 25.538992814206484,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 126.76036003294328,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 579.3093203051748,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 1060.0671657960963,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 5282.886883391018,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 224.1869307217165,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 1035.0655944260818,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 2216.0959552806107,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 9918.355141783599,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 1653.8649220445266,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 1260.3760557243859,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 5457.586622168595,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 10899.071248154058,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 52365.20202133414,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 673.3051196945404,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 2901.241530863421,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 5703.952704291902,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 27756.274851530703,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 5595.8512839909245,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 86860.53299681786,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 328885.7715743715,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 26.216310473139828,
            "unit": "ns"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "abauer@janestreet.com",
            "name": "Aaron Bauer",
            "username": "awilliambauer"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "0f1d019f9ef08ad0f278510d7706ef082427275f",
          "message": "Mark some week 1 exercises as optional",
          "timestamp": "2026-06-17T12:26:41-04:00",
          "tree_id": "6dcfcef56ccaac939f96e89745df6177d1b9c681",
          "url": "https://github.com/jane-street-immersion-program/jsip-exchange/commit/0f1d019f9ef08ad0f278510d7706ef082427275f"
        },
        "date": 1781713849297,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 21.43611200314105,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 21.21731707543254,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 21.259406316074248,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 21.46986817991373,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 113.08457035754238,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 521.3737304420221,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 1081.9752715762925,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 5621.345593491914,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 196.50880120477902,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 930.5371189976896,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 1829.8335182424669,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 8996.18178441938,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 1421.9399501568273,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 1097.5085993532996,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 4664.527996773918,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 9031.148105725359,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 43744.700397377994,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 564.3481861280651,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 2394.7628113589562,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 4793.532213850208,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 22667.861524869953,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 4756.07612284141,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 73853.5075889474,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 278596.6602156991,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 21.21582153117675,
            "unit": "ns"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "abauer@janestreet.com",
            "name": "Aaron Bauer",
            "username": "awilliambauer"
          },
          "committer": {
            "email": "abauer@janestreet.com",
            "name": "Aaron Bauer",
            "username": "awilliambauer"
          },
          "distinct": true,
          "id": "b0ae15c7c365c8cf0dbffaf50804509bcbaca67e",
          "message": "rename week 1 exercises to part 1",
          "timestamp": "2026-06-21T23:05:27-04:00",
          "tree_id": "c8f394b30c8f02e647436db505c85d0f2956a421",
          "url": "https://github.com/jane-street-immersion-program/jsip-exchange/commit/b0ae15c7c365c8cf0dbffaf50804509bcbaca67e"
        },
        "date": 1782098298110,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 23.21317800682068,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 23.11989311562119,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 22.7362345657823,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 23.00960472289039,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 126.87324074356442,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 580.3202625401467,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 1143.3907828361723,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 5630.086564832234,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 214.34011406858414,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 1008.8674494127819,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 1992.5559112280253,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 9696.256154144265,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 1596.7562707212578,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 1130.900053628202,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 4818.003736679931,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 9362.916350113897,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 41302.52431530442,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 550.0029780569765,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 2337.2235928577243,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 4552.580996605893,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 22263.495851659332,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 4717.094343822292,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 71609.36368909257,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 261256.2866117373,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 21.468669766202854,
            "unit": "ns"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "abauer@janestreet.com",
            "name": "Aaron Bauer",
            "username": "awilliambauer"
          },
          "committer": {
            "email": "abauer@janestreet.com",
            "name": "Aaron Bauer",
            "username": "awilliambauer"
          },
          "distinct": true,
          "id": "bb34e74166f598bb43ccab1043d5907e58f4ebd5",
          "message": "part 2 exercises",
          "timestamp": "2026-06-21T23:06:56-04:00",
          "tree_id": "ca59f6a2259e45a4be850a8253b874d7156f77d0",
          "url": "https://github.com/jane-street-immersion-program/jsip-exchange/commit/bb34e74166f598bb43ccab1043d5907e58f4ebd5"
        },
        "date": 1782098303290,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 22.426419649110272,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 22.981128243160754,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 22.444411945410387,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 21.194405156686912,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 118.29423164732394,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 564.154952708587,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 1110.3035056333654,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 5014.068638640015,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 213.85295780547935,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 1007.8024459891404,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 1992.3081402359446,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 9870.664796781904,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 1543.220499838631,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 1154.0750382257543,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 5015.204976188527,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 9720.604374548595,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 46396.85332726942,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 596.7397697775467,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 2574.749545512771,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 5029.189044382305,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 24600.235293183778,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 4927.4820939172705,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 75840.94144043428,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 262205.3591154294,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 21.535249041071616,
            "unit": "ns"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "abauer@janestreet.com",
            "name": "Aaron Bauer",
            "username": "awilliambauer"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "102e5c4fc85053d438aa1f8fd166f469191a5efb",
          "message": "Merge pull request #2 from jane-street-immersion-program/test-branch-protection\n\nTest branch protection",
          "timestamp": "2026-06-29T15:26:30+08:00",
          "tree_id": "f246b57a32f0e35ff8cdf87290e7dd48c6f23876",
          "url": "https://github.com/jane-street-immersion-program/jsip-exchange/commit/102e5c4fc85053d438aa1f8fd166f469191a5efb"
        },
        "date": 1782718217266,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 26.57565437868886,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 26.343264845542304,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 26.651803370391054,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 29.44470550090274,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 25.32628671048503,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 27.323477004831997,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 27.931983236301893,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 30.135649803473893,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 168.1206785998382,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 715.0277362607864,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 1417.3804934872571,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 6961.912460754476,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 451.9035735405611,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 120.98578687797588,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 128.44479309995532,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 124.944621002394,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 123.65508658230034,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 62.134111679988024,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 63.157894757382685,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 62.13475289937716,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 61.20657240567847,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 7529.649766532869,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 70924.60016600936,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 222924.27867354683,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 30.846377637484867,
            "unit": "ns"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "abauer@janestreet.com",
            "name": "Aaron Bauer",
            "username": "awilliambauer"
          },
          "committer": {
            "email": "abauer@janestreet.com",
            "name": "Aaron Bauer",
            "username": "awilliambauer"
          },
          "distinct": true,
          "id": "bb34e74166f598bb43ccab1043d5907e58f4ebd5",
          "message": "part 2 exercises",
          "timestamp": "2026-06-21T23:06:56-04:00",
          "tree_id": "ca59f6a2259e45a4be850a8253b874d7156f77d0",
          "url": "https://github.com/jane-street-immersion-program/jsip-exchange/commit/bb34e74166f598bb43ccab1043d5907e58f4ebd5"
        },
        "date": 1782718466352,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 22.42473095640716,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 22.73695878370806,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 22.480912199196585,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 21.63858143178415,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 117.47999956804023,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 565.9115378810905,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 1141.461105993562,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 5634.707780173528,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 213.9695537460096,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 1010.4595838714507,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 2011.2728278693507,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 9691.992988818118,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 1545.242699413814,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 1156.0997227145028,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 5009.258110021343,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 9836.060621550445,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 47320.16506448435,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 596.661078961647,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 2573.6804321690133,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 5013.869388770591,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 24291.265995257072,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 4938.9915996485715,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 79067.4029785219,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 292978.44210195384,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 22.702325991856416,
            "unit": "ns"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "abauer@janestreet.com",
            "name": "Aaron Bauer",
            "username": "awilliambauer"
          },
          "committer": {
            "email": "abauer@janestreet.com",
            "name": "Aaron Bauer",
            "username": "awilliambauer"
          },
          "distinct": true,
          "id": "6badd820fc3bd340e9603e89ed47e4f65040bcae",
          "message": "ai intro, part 3 exercises and claude code files",
          "timestamp": "2026-07-01T11:40:44+08:00",
          "tree_id": "3858b9d6e66f8255e17d763da89c83a3b6aefb4b",
          "url": "https://github.com/jane-street-immersion-program/jsip-exchange/commit/6badd820fc3bd340e9603e89ed47e4f65040bcae"
        },
        "date": 1782877521611,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 20.005691207732994,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 19.552439363009384,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 19.086733620938606,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 18.867943498667305,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 88.35454962679329,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 395.9138665325393,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 783.6910537409824,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 3901.29103450467,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 166.83064122685076,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 779.8159690174381,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 1536.727717406335,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 7680.924894245951,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 1293.724934761568,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 1002.9605614248394,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 4447.889539830825,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 8759.160014646035,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 39886.112586655414,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 509.4667278074531,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 2209.891915808196,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 4316.130635231406,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 20455.242376906222,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 4160.66852497509,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 66323.86473868522,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 250818.9437644404,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 20.33350482062443,
            "unit": "ns"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "abauer@janestreet.com",
            "name": "Aaron Bauer",
            "username": "awilliambauer"
          },
          "committer": {
            "email": "abauer@janestreet.com",
            "name": "Aaron Bauer",
            "username": "awilliambauer"
          },
          "distinct": true,
          "id": "fb29290768ac9b6af64651de9f9aa0b6c4454e98",
          "message": "part 4 instructions and starter code",
          "timestamp": "2026-07-07T17:20:35-04:00",
          "tree_id": "2bece0593627bea3fbacc142db9793aeb1d4921e",
          "url": "https://github.com/jane-street-immersion-program/jsip-exchange/commit/fb29290768ac9b6af64651de9f9aa0b6c4454e98"
        },
        "date": 1783459474932,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 22.902524160638745,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 23.03137305638349,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 22.29717987915379,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 22.34271957712548,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 119.01797485980194,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 501.74760145006417,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 984.4676542194572,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 5574.4608215226335,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 205.46644862604143,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 915.2116206632627,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 1989.234156342577,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 9684.994551954047,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 1541.1993401735688,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 1101.6326469918909,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 4493.726870055329,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 8723.853319147214,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 46929.845648370676,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 599.3911656604639,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 2574.555803643413,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 5026.042042090881,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 24585.17638501227,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 5028.951716969704,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 78399.58953408599,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 263913.2577475736,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 21.786591309688998,
            "unit": "ns"
          }
        ]
      }
    ]
  }
}