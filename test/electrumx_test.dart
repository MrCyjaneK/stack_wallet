// import 'dart:io';
//
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:stackwallet/electrumx_rpc/electrumx_client.dart';
// import 'package:stackwallet/electrumx_rpc/rpc.dart';
// import 'package:stackwallet/services/event_bus/events/global/tor_connection_status_changed_event.dart';
// import 'package:stackwallet/services/tor_service.dart';
// import 'package:stackwallet/utilities/prefs.dart';
//
// import 'electrumx_test.mocks.dart';
// import 'sample_data/get_anonymity_set_sample_data.dart';
// import 'sample_data/get_used_serials_sample_data.dart';
// import 'sample_data/transaction_data_samples.dart';
//
// @GenerateMocks([JsonRPC, Prefs, TorService])
// void main() {
//   group("factory constructors and getters", () {
//     test("electrumxnode .from factory", () {
//       final nodeA = ElectrumXNode(
//         address: "some address",
//         port: 1,
//         name: "some name",
//         id: "some ID",
//         useSSL: true,
//       );
//
//       final nodeB = ElectrumXNode.from(nodeA);
//
//       expect(nodeB.toString(), nodeA.toString());
//       expect(nodeA == nodeB, false);
//     });
//
//     test("electrumx .from factory", () {
//       final node = ElectrumXNode(
//         address: "some address",
//         port: 1,
//         name: "some name",
//         id: "some ID",
//         useSSL: true,
//       );
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//
//       final client = ElectrumXClient.from(
//         node: node,
//         failovers: [],
//         prefs: mockPrefs,
//         torService: torService,
//       );
//
//       expect(client.useSSL, node.useSSL);
//       expect(client.host, node.address);
//       expect(client.port, node.port);
//       expect(client.rpcClient, null);
//
//       verifyNoMoreInteractions(mockPrefs);
//     });
//   });
//
//   test("Server error", () {
//     final mockClient = MockJsonRPC();
//     const command = "blockchain.transaction.get";
//     const jsonArgs = '["",true]';
//     when(
//       mockClient.request(
//         '{"jsonrpc": "2.0", "id": "some requestId",'
//         '"method": "$command","params": $jsonArgs}',
//         const Duration(seconds: 60),
//       ),
//     ).thenAnswer(
//       (_) async => JsonRPCResponse(data: {
//         "jsonrpc": "2.0",
//         "error": {
//           "code": 1,
//           "message": "None should be a transaction hash",
//         },
//         "id": "some requestId",
//       }),
//     );
//
//     final mockPrefs = MockPrefs();
//     when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//     final torService = MockTorService();
//     when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//
//     final client = ElectrumXClient(
//       host: "some server",
//       port: 0,
//       useSSL: true,
//       client: mockClient,
//       failovers: [],
//       prefs: mockPrefs,
//       torService: torService,
//     );
//
//     expect(() => client.getTransaction(requestID: "some requestId", txHash: ''),
//         throwsA(isA<Exception>()));
//
//     verify(mockPrefs.wifiOnly).called(1);
//     verifyNoMoreInteractions(mockPrefs);
//   });
//
//   group("getBlockHeadTip", () {
//     test("getBlockHeadTip success", () async {
//       final mockClient = MockJsonRPC();
//       const command = "blockchain.headers.subscribe";
//       const jsonArgs = '[]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 60),
//         ),
//       ).thenAnswer(
//         (_) async => JsonRPCResponse(data: {
//           "jsonrpc": "2.0",
//           "result": {"height": 520481, "hex": "some block hex string"},
//           "id": "some requestId"
//         }),
//       );
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       final result =
//           await (client.getBlockHeadTip(requestID: "some requestId"));
//
//       expect(result["height"], 520481);
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verify(mockPrefs.useTor).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//
//     test("getBlockHeadTip throws/fails", () {
//       final mockClient = MockJsonRPC();
//       const command = "blockchain.headers.subscribe";
//       const jsonArgs = '[]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 60),
//         ),
//       ).thenThrow(Exception());
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       expect(() => client.getBlockHeadTip(requestID: "some requestId"),
//           throwsA(isA<Exception>()));
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//   });
//
//   group("ping", () {
//     test("ping success", () async {
//       final mockClient = MockJsonRPC();
//       const command = "server.ping";
//       const jsonArgs = '[]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 2),
//         ),
//       ).thenAnswer(
//         (_) async => JsonRPCResponse(data: {
//           "jsonrpc": "2.0",
//           "result": null,
//           "id": "some requestId",
//         }),
//       );
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       final result = await client.ping(requestID: "some requestId");
//
//       expect(result, true);
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verify(mockPrefs.useTor).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//
//     test("ping throws/fails", () {
//       final mockClient = MockJsonRPC();
//       const command = "server.ping";
//       const jsonArgs = '[]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 2),
//         ),
//       ).thenThrow(Exception());
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       expect(() => client.ping(requestID: "some requestId"),
//           throwsA(isA<Exception>()));
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//   });
//
//   group("getServerFeatures", () {
//     test("getServerFeatures success", () async {
//       final mockClient = MockJsonRPC();
//       const command = "server.features";
//       const jsonArgs = '[]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 60),
//         ),
//       ).thenAnswer(
//         (_) async => JsonRPCResponse(data: {
//           "jsonrpc": "2.0",
//           "result": {
//             "genesis_hash":
//                 "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943",
//             "hosts": {
//               "0.0.0.0": {"tcp_port": 51001, "ssl_port": 51002}
//             },
//             "protocol_max": "1.0",
//             "protocol_min": "1.0",
//             "pruning": null,
//             "server_version": "ElectrumX 1.0.17",
//             "hash_function": "sha256"
//           },
//           "id": "some requestId"
//         }),
//       );
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       final result =
//           await client.getServerFeatures(requestID: "some requestId");
//
//       expect(result, {
//         "genesis_hash":
//             "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943",
//         "hosts": {
//           "0.0.0.0": {"tcp_port": 51001, "ssl_port": 51002}
//         },
//         "protocol_max": "1.0",
//         "protocol_min": "1.0",
//         "pruning": null,
//         "server_version": "ElectrumX 1.0.17",
//         "hash_function": "sha256",
//       });
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verify(mockPrefs.useTor).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//
//     test("getServerFeatures throws/fails", () {
//       final mockClient = MockJsonRPC();
//       const command = "server.features";
//       const jsonArgs = '[]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 60),
//         ),
//       ).thenThrow(Exception());
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       expect(() => client.getServerFeatures(requestID: "some requestId"),
//           throwsA(isA<Exception>()));
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//   });
//
//   group("broadcastTransaction", () {
//     test("broadcastTransaction success", () async {
//       final mockClient = MockJsonRPC();
//       const command = "blockchain.transaction.broadcast";
//       const jsonArgs = '["some raw transaction string"]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 60),
//         ),
//       ).thenAnswer(
//         (_) async => JsonRPCResponse(data: {
//           "jsonrpc": "2.0",
//           "result": "the txid of the rawtx",
//           "id": "some requestId"
//         }),
//       );
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       final result = await client.broadcastTransaction(
//           rawTx: "some raw transaction string", requestID: "some requestId");
//
//       expect(result, "the txid of the rawtx");
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verify(mockPrefs.useTor).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//
//     test("broadcastTransaction throws/fails", () {
//       final mockClient = MockJsonRPC();
//       const command = "blockchain.transaction.broadcast";
//       const jsonArgs = '["some raw transaction string"]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 60),
//         ),
//       ).thenThrow(Exception());
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       expect(
//           () => client.broadcastTransaction(
//               rawTx: "some raw transaction string",
//               requestID: "some requestId"),
//           throwsA(isA<Exception>()));
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//   });
//
//   group("getBalance", () {
//     test("getBalance success", () async {
//       final mockClient = MockJsonRPC();
//       const command = "blockchain.scripthash.get_balance";
//       const jsonArgs = '["dummy hash"]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 60),
//         ),
//       ).thenAnswer(
//         (_) async => JsonRPCResponse(data: {
//           "jsonrpc": "2.0",
//           "result": {
//             "confirmed": 103873966,
//             "unconfirmed": 23684400,
//           },
//           "id": "some requestId"
//         }),
//       );
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       final result = await client.getBalance(
//           scripthash: "dummy hash", requestID: "some requestId");
//
//       expect(result, {"confirmed": 103873966, "unconfirmed": 23684400});
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verify(mockPrefs.useTor).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//
//     test("getBalance throws/fails", () {
//       final mockClient = MockJsonRPC();
//       const command = "blockchain.scripthash.get_balance";
//       const jsonArgs = '["dummy hash"]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 60),
//         ),
//       ).thenThrow(Exception());
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       expect(
//           () => client.getBalance(
//               scripthash: "dummy hash", requestID: "some requestId"),
//           throwsA(isA<Exception>()));
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//   });
//
//   group("getHistory", () {
//     test("getHistory success", () async {
//       final mockClient = MockJsonRPC();
//       const command = "blockchain.scripthash.get_history";
//       const jsonArgs = '["dummy hash"]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(minutes: 5),
//         ),
//       ).thenAnswer(
//         (_) async => JsonRPCResponse(data: {
//           "jsonrpc": "2.0",
//           "result": [
//             {
//               "height": 200004,
//               "tx_hash":
//                   "acc3758bd2a26f869fcc67d48ff30b96464d476bca82c1cd6656e7d506816412"
//             },
//             {
//               "height": 215008,
//               "tx_hash":
//                   "f3e1bf48975b8d6060a9de8884296abb80be618dc00ae3cb2f6cee3085e09403"
//             }
//           ],
//           "id": "some requestId"
//         }),
//       );
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       final result = await client.getHistory(
//           scripthash: "dummy hash", requestID: "some requestId");
//
//       expect(result, [
//         {
//           "height": 200004,
//           "tx_hash":
//               "acc3758bd2a26f869fcc67d48ff30b96464d476bca82c1cd6656e7d506816412"
//         },
//         {
//           "height": 215008,
//           "tx_hash":
//               "f3e1bf48975b8d6060a9de8884296abb80be618dc00ae3cb2f6cee3085e09403"
//         }
//       ]);
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verify(mockPrefs.useTor).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//
//     test("getHistory throws/fails", () {
//       final mockClient = MockJsonRPC();
//       const command = "blockchain.scripthash.get_history";
//       const jsonArgs = '["dummy hash"]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(minutes: 5),
//         ),
//       ).thenThrow(Exception());
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       expect(
//           () => client.getHistory(
//               scripthash: "dummy hash", requestID: "some requestId"),
//           throwsA(isA<Exception>()));
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//   });
//
//   group("getUTXOs", () {
//     test("getUTXOs success", () async {
//       final mockClient = MockJsonRPC();
//       const command = "blockchain.scripthash.listunspent";
//       const jsonArgs = '["dummy hash"]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 60),
//         ),
//       ).thenAnswer(
//         (_) async => JsonRPCResponse(data: {
//           "jsonrpc": "2.0",
//           "result": [
//             {
//               "tx_pos": 0,
//               "value": 45318048,
//               "tx_hash":
//                   "9f2c45a12db0144909b5db269415f7319179105982ac70ed80d76ea79d923ebf",
//               "height": 437146
//             },
//             {
//               "tx_pos": 0,
//               "value": 919195,
//               "tx_hash":
//                   "3d2290c93436a3e964cfc2f0950174d8847b1fbe3946432c4784e168da0f019f",
//               "height": 441696
//             }
//           ],
//           "id": "some requestId"
//         }),
//       );
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       final result = await client.getUTXOs(
//           scripthash: "dummy hash", requestID: "some requestId");
//
//       expect(result, [
//         {
//           "tx_pos": 0,
//           "value": 45318048,
//           "tx_hash":
//               "9f2c45a12db0144909b5db269415f7319179105982ac70ed80d76ea79d923ebf",
//           "height": 437146
//         },
//         {
//           "tx_pos": 0,
//           "value": 919195,
//           "tx_hash":
//               "3d2290c93436a3e964cfc2f0950174d8847b1fbe3946432c4784e168da0f019f",
//           "height": 441696
//         }
//       ]);
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verify(mockPrefs.useTor).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//
//     test("getUTXOs throws/fails", () {
//       final mockClient = MockJsonRPC();
//       const command = "blockchain.scripthash.listunspent";
//       const jsonArgs = '["dummy hash"]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 60),
//         ),
//       ).thenThrow(Exception());
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       expect(
//           () => client.getUTXOs(
//               scripthash: "dummy hash", requestID: "some requestId"),
//           throwsA(isA<Exception>()));
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//   });
//
//   group("getTransaction", () {
//     test("getTransaction success", () async {
//       final mockClient = MockJsonRPC();
//       const command = "blockchain.transaction.get";
//       const jsonArgs = '["${SampleGetTransactionData.txHash0}",true]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 60),
//         ),
//       ).thenAnswer(
//         (_) async => JsonRPCResponse(data: {
//           "jsonrpc": "2.0",
//           "result": SampleGetTransactionData.txData0,
//           "id": "some requestId"
//         }),
//       );
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       final result = await client.getTransaction(
//           txHash: SampleGetTransactionData.txHash0,
//           verbose: true,
//           requestID: "some requestId");
//
//       expect(result, SampleGetTransactionData.txData0);
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verify(mockPrefs.useTor).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//
//     test("getTransaction throws/fails", () {
//       final mockClient = MockJsonRPC();
//       const command = "blockchain.transaction.get";
//       const jsonArgs = '["${SampleGetTransactionData.txHash0}",true]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 60),
//         ),
//       ).thenThrow(Exception());
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       expect(
//           () => client.getTransaction(
//               txHash: SampleGetTransactionData.txHash0,
//               requestID: "some requestId"),
//           throwsA(isA<Exception>()));
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//   });
//
//   group("getAnonymitySet", () {
//     test("getAnonymitySet success", () async {
//       final mockClient = MockJsonRPC();
//       const command = "lelantus.getanonymityset";
//       const jsonArgs = '["1",""]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 60),
//         ),
//       ).thenAnswer(
//         (_) async => JsonRPCResponse(data: {
//           "jsonrpc": "2.0",
//           "result": GetAnonymitySetSampleData.data,
//           "id": "some requestId"
//         }),
//       );
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       final result = await client.getLelantusAnonymitySet(
//           groupId: "1", blockhash: "", requestID: "some requestId");
//
//       expect(result, GetAnonymitySetSampleData.data);
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verify(mockPrefs.useTor).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//
//     test("getAnonymitySet throws/fails", () {
//       final mockClient = MockJsonRPC();
//       const command = "lelantus.getanonymityset";
//       const jsonArgs = '["1",""]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 60),
//         ),
//       ).thenThrow(Exception());
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       expect(
//           () => client.getLelantusAnonymitySet(
//               groupId: "1", requestID: "some requestId"),
//           throwsA(isA<Exception>()));
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//   });
//
//   group("getMintData", () {
//     test("getMintData success", () async {
//       final mockClient = MockJsonRPC();
//       const command = "lelantus.getmintmetadata";
//       const jsonArgs = '["some mints"]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 60),
//         ),
//       ).thenAnswer(
//         (_) async => JsonRPCResponse(data: {
//           "jsonrpc": "2.0",
//           "result": "mint meta data",
//           "id": "some requestId"
//         }),
//       );
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       final result = await client.getLelantusMintData(
//           mints: "some mints", requestID: "some requestId");
//
//       expect(result, "mint meta data");
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verify(mockPrefs.useTor).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//
//     test("getMintData throws/fails", () {
//       final mockClient = MockJsonRPC();
//       const command = "lelantus.getmintmetadata";
//       const jsonArgs = '["some mints"]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 60),
//         ),
//       ).thenThrow(Exception());
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       expect(
//           () => client.getLelantusMintData(
//               mints: "some mints", requestID: "some requestId"),
//           throwsA(isA<Exception>()));
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//   });
//
//   group("getUsedCoinSerials", () {
//     test("getUsedCoinSerials success", () async {
//       final mockClient = MockJsonRPC();
//       const command = "lelantus.getusedcoinserials";
//       const jsonArgs = '["0"]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(minutes: 2),
//         ),
//       ).thenAnswer(
//         (_) async => JsonRPCResponse(data: {
//           "jsonrpc": "2.0",
//           "result": GetUsedSerialsSampleData.serials,
//           "id": "some requestId"
//         }),
//       );
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       final result = await client.getLelantusUsedCoinSerials(
//           requestID: "some requestId", startNumber: 0);
//
//       expect(result, GetUsedSerialsSampleData.serials);
//
//       verify(mockPrefs.wifiOnly).called(3);
//       verify(mockPrefs.useTor).called(3);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//
//     test("getUsedCoinSerials throws/fails", () {
//       final mockClient = MockJsonRPC();
//       const command = "lelantus.getusedcoinserials";
//       const jsonArgs = '["0"]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(minutes: 2),
//         ),
//       ).thenThrow(Exception());
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       expect(
//           () => client.getLelantusUsedCoinSerials(
//               requestID: "some requestId", startNumber: 0),
//           throwsA(isA<Exception>()));
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//   });
//
//   group("getLatestCoinId", () {
//     test("getLatestCoinId success", () async {
//       final mockClient = MockJsonRPC();
//       const command = "lelantus.getlatestcoinid";
//       const jsonArgs = '[]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 60),
//         ),
//       ).thenAnswer(
//         (_) async => JsonRPCResponse(data: {
//           "jsonrpc": "2.0",
//           "result": 1,
//           "id": "some requestId",
//         }),
//       );
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       final result =
//           await client.getLelantusLatestCoinId(requestID: "some requestId");
//
//       expect(result, 1);
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verify(mockPrefs.useTor).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//
//     test("getLatestCoinId throws/fails", () {
//       final mockClient = MockJsonRPC();
//       const command = "lelantus.getlatestcoinid";
//       const jsonArgs = '[]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 60),
//         ),
//       ).thenThrow(Exception());
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       expect(
//           () => client.getLelantusLatestCoinId(
//                 requestID: "some requestId",
//               ),
//           throwsA(isA<Exception>()));
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//   });
//
//   group("getCoinsForRecovery", () {
//     test("getCoinsForRecovery success", () async {
//       final mockClient = MockJsonRPC();
//       const command = "lelantus.getanonymityset";
//       const jsonArgs = '["1",""]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 60),
//         ),
//       ).thenAnswer(
//         (_) async => JsonRPCResponse(data: {
//           "jsonrpc": "2.0",
//           "result": GetAnonymitySetSampleData.data,
//           "id": "some requestId"
//         }),
//       );
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       final result = await client.getLelantusAnonymitySet(
//           groupId: "1", blockhash: "", requestID: "some requestId");
//
//       expect(result, GetAnonymitySetSampleData.data);
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verify(mockPrefs.useTor).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//
//     test("getAnonymitySet throws/fails", () {
//       final mockClient = MockJsonRPC();
//       const command = "lelantus.getanonymityset";
//       const jsonArgs = '["1",""]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 60),
//         ),
//       ).thenThrow(Exception());
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       expect(
//           () => client.getLelantusAnonymitySet(
//                 groupId: "1",
//                 requestID: "some requestId",
//               ),
//           throwsA(isA<Exception>()));
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//   });
//
//   group("getMintData", () {
//     test("getMintData success", () async {
//       final mockClient = MockJsonRPC();
//       const command = "lelantus.getmintmetadata";
//       const jsonArgs = '["some mints"]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 60),
//         ),
//       ).thenAnswer(
//         (_) async => JsonRPCResponse(data: {
//           "jsonrpc": "2.0",
//           "result": "mint meta data",
//           "id": "some requestId"
//         }),
//       );
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       final result = await client.getLelantusMintData(
//           mints: "some mints", requestID: "some requestId");
//
//       expect(result, "mint meta data");
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verify(mockPrefs.useTor).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//
//     test("getMintData throws/fails", () {
//       final mockClient = MockJsonRPC();
//       const command = "lelantus.getmintmetadata";
//       const jsonArgs = '["some mints"]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 60),
//         ),
//       ).thenThrow(Exception());
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       expect(
//           () => client.getLelantusMintData(
//                 mints: "some mints",
//                 requestID: "some requestId",
//               ),
//           throwsA(isA<Exception>()));
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//   });
//
//   group("getUsedCoinSerials", () {
//     test("getUsedCoinSerials success", () async {
//       final mockClient = MockJsonRPC();
//       const command = "lelantus.getusedcoinserials";
//       const jsonArgs = '["0"]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(minutes: 2),
//         ),
//       ).thenAnswer(
//         (_) async => JsonRPCResponse(data: {
//           "jsonrpc": "2.0",
//           "result": GetUsedSerialsSampleData.serials,
//           "id": "some requestId"
//         }),
//       );
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       final result = await client.getLelantusUsedCoinSerials(
//           requestID: "some requestId", startNumber: 0);
//
//       expect(result, GetUsedSerialsSampleData.serials);
//
//       verify(mockPrefs.wifiOnly).called(3);
//       verify(mockPrefs.useTor).called(3);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//
//     test("getUsedCoinSerials throws/fails", () {
//       final mockClient = MockJsonRPC();
//       const command = "lelantus.getusedcoinserials";
//       const jsonArgs = '["0"]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(minutes: 2),
//         ),
//       ).thenThrow(Exception());
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       expect(
//           () => client.getLelantusUsedCoinSerials(
//               requestID: "some requestId", startNumber: 0),
//           throwsA(isA<Exception>()));
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//   });
//
//   group("getLatestCoinId", () {
//     test("getLatestCoinId success", () async {
//       final mockClient = MockJsonRPC();
//       const command = "lelantus.getlatestcoinid";
//       const jsonArgs = '[]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 60),
//         ),
//       ).thenAnswer(
//         (_) async => JsonRPCResponse(data: {
//           "jsonrpc": "2.0",
//           "result": 1,
//           "id": "some requestId",
//         }),
//       );
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       final result =
//           await client.getLelantusLatestCoinId(requestID: "some requestId");
//
//       expect(result, 1);
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verify(mockPrefs.useTor).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//
//     test("getLatestCoinId throws/fails", () {
//       final mockClient = MockJsonRPC();
//       const command = "lelantus.getlatestcoinid";
//       const jsonArgs = '[]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 60),
//         ),
//       ).thenThrow(Exception());
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       expect(() => client.getLelantusLatestCoinId(requestID: "some requestId"),
//           throwsA(isA<Exception>()));
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//   });
//
//   group("getFeeRate", () {
//     test("getFeeRate success", () async {
//       final mockClient = MockJsonRPC();
//       const command = "blockchain.getfeerate";
//       const jsonArgs = '[]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 60),
//         ),
//       ).thenAnswer(
//         (_) async => JsonRPCResponse(data: {
//           "jsonrpc": "2.0",
//           "result": {
//             "rate": 1000,
//           },
//           "id": "some requestId"
//         }),
//       );
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       final result = await client.getFeeRate(requestID: "some requestId");
//
//       expect(result, {"rate": 1000});
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verify(mockPrefs.useTor).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//
//     test("getFeeRate throws/fails", () {
//       final mockClient = MockJsonRPC();
//       const command = "blockchain.getfeerate";
//       const jsonArgs = '[]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 60),
//         ),
//       ).thenThrow(Exception());
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//       final torService = MockTorService();
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: torService,
//           failovers: []);
//
//       expect(() => client.getFeeRate(requestID: "some requestId"),
//           throwsA(isA<Exception>()));
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//     });
//   });
//
//   test("rpcClient is null throws with bad server info", () {
//     final mockPrefs = MockPrefs();
//     when(mockPrefs.useTor).thenAnswer((realInvocation) => false);
//     final torService = MockTorService();
//     when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//     final client = ElectrumXClient(
//       client: null,
//       port: -10,
//       host: "_ :sa  %",
//       useSSL: false,
//       prefs: mockPrefs,
//       torService: torService,
//       failovers: [],
//     );
//
//     expect(() => client.getFeeRate(), throwsA(isA<Exception>()));
//
//     verify(mockPrefs.wifiOnly).called(1);
//     verifyNoMoreInteractions(mockPrefs);
//   });
//
//   group("Tor tests", () {
//     // useTor is false, so no TorService calls should be made.
//     test("Tor not in use", () async {
//       final mockClient = MockJsonRPC();
//       const command = "blockchain.transaction.get";
//       const jsonArgs = '["${SampleGetTransactionData.txHash0}",true]';
//       when(mockClient.request(
//         '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}',
//         const Duration(seconds: 60),
//       )).thenAnswer((_) async => JsonRPCResponse(data: {
//             "jsonrpc": "2.0",
//             "result": SampleGetTransactionData.txData0,
//             "id": "some requestId",
//           }));
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((_) => false);
//       when(mockPrefs.torKillSwitch)
//           .thenAnswer((_) => false); // Or true, shouldn't matter.
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final mockTorService = MockTorService();
//       when(mockTorService.status)
//           .thenAnswer((_) => TorConnectionStatus.disconnected);
//
//       final client = ElectrumXClient(
//         host: "some server",
//         port: 0,
//         useSSL: true,
//         client: mockClient,
//         failovers: [],
//         prefs: mockPrefs,
//         torService: mockTorService,
//       );
//
//       final result = await client.getTransaction(
//           txHash: SampleGetTransactionData.txHash0,
//           verbose: true,
//           requestID: "some requestId");
//
//       expect(result, SampleGetTransactionData.txData0);
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verify(mockPrefs.useTor).called(1);
//       verifyNever(mockPrefs.torKillSwitch);
//       verifyNoMoreInteractions(mockPrefs);
//       verifyNever(mockTorService.status);
//       verifyNoMoreInteractions(mockTorService);
//     });
//
//     // useTor is true, but TorService is not enabled and the killswitch is off, so a clearnet call should be made.
//     test("Tor in use but Tor unavailable and killswitch off", () async {
//       final mockClient = MockJsonRPC();
//       const command = "blockchain.transaction.get";
//       const jsonArgs = '["${SampleGetTransactionData.txHash0}",true]';
//       when(mockClient.request(
//         '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}',
//         const Duration(seconds: 60),
//       )).thenAnswer((_) async => JsonRPCResponse(data: {
//             "jsonrpc": "2.0",
//             "result": SampleGetTransactionData.txData0,
//             "id": "some requestId",
//           }));
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((_) => true);
//       when(mockPrefs.torKillSwitch).thenAnswer((_) => false);
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//
//       final mockTorService = MockTorService();
//       when(mockTorService.status)
//           .thenAnswer((_) => TorConnectionStatus.disconnected);
//       when(mockTorService.getProxyInfo()).thenAnswer((_) => (
//             host: InternetAddress('1.2.3.4'),
//             port: -1
//           )); // Port is set to -1 until Tor is enabled.
//
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: mockTorService,
//           failovers: []);
//
//       final result = await client.getTransaction(
//           txHash: SampleGetTransactionData.txHash0,
//           verbose: true,
//           requestID: "some requestId");
//
//       expect(result, SampleGetTransactionData.txData0);
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verify(mockPrefs.useTor).called(1);
//       verify(mockPrefs.torKillSwitch).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//       verify(mockTorService.status).called(1);
//       verifyNever(mockTorService.getProxyInfo());
//       verifyNoMoreInteractions(mockTorService);
//     });
//
//     // useTor is true and TorService is enabled, so a TorService call should be made.
//     test("Tor in use and available", () async {
//       final mockClient = MockJsonRPC();
//       const command = "blockchain.transaction.get";
//       const jsonArgs = '["${SampleGetTransactionData.txHash0}",true]';
//       when(mockClient.request(
//         '{"jsonrpc": "2.0", "id": "some requestId","method": "$command","params": $jsonArgs}',
//         const Duration(seconds: 60),
//       )).thenAnswer((_) async => JsonRPCResponse(data: {
//             "jsonrpc": "2.0",
//             "result": SampleGetTransactionData.txData0,
//             "id": "some requestId",
//           }));
//       when(mockClient.proxyInfo)
//           .thenAnswer((_) => (host: InternetAddress('1.2.3.4'), port: 42));
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((_) => true);
//       when(mockPrefs.torKillSwitch).thenAnswer((_) => false); // Or true.
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//
//       final mockTorService = MockTorService();
//       when(mockTorService.status)
//           .thenAnswer((_) => TorConnectionStatus.connected);
//       when(mockTorService.getProxyInfo())
//           .thenAnswer((_) => (host: InternetAddress('1.2.3.4'), port: 42));
//
//       final client = ElectrumXClient(
//           host: "some server",
//           port: 0,
//           useSSL: true,
//           client: mockClient,
//           prefs: mockPrefs,
//           torService: mockTorService,
//           failovers: []);
//
//       final result = await client.getTransaction(
//           txHash: SampleGetTransactionData.txHash0,
//           verbose: true,
//           requestID: "some requestId");
//
//       expect(result, SampleGetTransactionData.txData0);
//
//       verify(mockClient.proxyInfo).called(1);
//       verify(mockPrefs.wifiOnly).called(1);
//       verify(mockPrefs.useTor).called(1);
//       verifyNever(mockPrefs.torKillSwitch);
//       verifyNoMoreInteractions(mockPrefs);
//       verify(mockTorService.status).called(1);
//       verify(mockTorService.getProxyInfo()).called(1);
//       verifyNoMoreInteractions(mockTorService);
//     });
//
//     // useTor is true, but TorService is not enabled and the killswitch is on, so no TorService calls should be made.
//     test("killswitch enabled", () async {
//       final mockClient = MockJsonRPC();
//       const command = "blockchain.transaction.get";
//       const jsonArgs = '["",true]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 60),
//         ),
//       ).thenAnswer(
//         (_) async => JsonRPCResponse(data: {
//           "jsonrpc": "2.0",
//           "error": {
//             "code": 1,
//             "message": "None should be a transaction hash",
//           },
//           "id": "some requestId",
//         }),
//       );
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((_) => true);
//       when(mockPrefs.torKillSwitch).thenAnswer((_) => true);
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final mockTorService = MockTorService();
//       when(mockTorService.status)
//           .thenAnswer((_) => TorConnectionStatus.disconnected);
//
//       final client = ElectrumXClient(
//         host: "some server",
//         port: 0,
//         useSSL: true,
//         client: mockClient,
//         failovers: [],
//         prefs: mockPrefs,
//         torService: mockTorService,
//       );
//
//       try {
//         var result = await client.getTransaction(
//             requestID: "some requestId", txHash: '');
//       } catch (e) {
//         expect(e, isA<Exception>());
//         expect(
//             e.toString(),
//             equals(
//                 "Exception: Tor preference and killswitch set but Tor is not enabled, not connecting to ElectrumX"));
//       }
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verify(mockPrefs.useTor).called(1);
//       verify(mockPrefs.torKillSwitch).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//       verify(mockTorService.status).called(1);
//       verifyNoMoreInteractions(mockTorService);
//     });
//
//     // useTor is true but Tor is not enabled, but because the killswitch is off, a clearnet call should be made.
//     test("killswitch disabled", () async {
//       final mockClient = MockJsonRPC();
//       const command = "blockchain.transaction.get";
//       const jsonArgs = '["${SampleGetTransactionData.txHash0}",true]';
//       when(
//         mockClient.request(
//           '{"jsonrpc": "2.0", "id": "some requestId",'
//           '"method": "$command","params": $jsonArgs}',
//           const Duration(seconds: 60),
//         ),
//       ).thenAnswer(
//         (_) async => JsonRPCResponse(data: {
//           "jsonrpc": "2.0",
//           "result": SampleGetTransactionData.txData0,
//           "id": "some requestId"
//         }),
//       );
//
//       final mockPrefs = MockPrefs();
//       when(mockPrefs.useTor).thenAnswer((_) => true);
//       when(mockPrefs.torKillSwitch).thenAnswer((_) => false);
//       when(mockPrefs.wifiOnly).thenAnswer((_) => false);
//       final mockTorService = MockTorService();
//       when(mockTorService.status)
//           .thenAnswer((_) => TorConnectionStatus.disconnected);
//
//       final client = ElectrumXClient(
//         host: "some server",
//         port: 0,
//         useSSL: true,
//         client: mockClient,
//         failovers: [],
//         prefs: mockPrefs,
//         torService: mockTorService,
//       );
//
//       final result = await client.getTransaction(
//           txHash: SampleGetTransactionData.txHash0,
//           verbose: true,
//           requestID: "some requestId");
//
//       expect(result, SampleGetTransactionData.txData0);
//
//       verify(mockPrefs.wifiOnly).called(1);
//       verify(mockPrefs.useTor).called(1);
//       verify(mockPrefs.torKillSwitch).called(1);
//       verifyNoMoreInteractions(mockPrefs);
//       verify(mockTorService.status).called(1);
//       verifyNoMoreInteractions(mockTorService);
//     });
//   });
// }
