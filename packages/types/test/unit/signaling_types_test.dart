// ignore_for_file: cascade_invocations

import 'package:ermes_types/ermes_types.dart';
import 'package:test/test.dart';

void main() {
  group('SignalData', () {
    test('should create instance with type and sdp', () {
      const signal = SignalData(
        type: 'offer',
        sdp: 'v=0\r\no=- 123 456 IN IP4 127.0.0.1',
      );

      expect(signal.type, equals('offer'));
      expect(signal.sdp, startsWith('v=0'));
    });

    test('should serialize and deserialize', () {
      const signal = SignalData(
        type: 'answer',
        sdp: 'sdp content',
      );

      final json = signal.toJson();
      final restored = SignalData.fromJson(json);

      expect(restored.type, equals(signal.type));
      expect(restored.sdp, equals(signal.sdp));
    });
  });

  group('Signal', () {
    test('should create signal from data', () {
      const signalData = SignalData(type: 'offer', sdp: 'sdp');
      const signal = Signal.data(signalData);

      signal.when(
        data: (data) => expect(data.type, equals('offer')),
        string: (_) => fail('Should be data type'),
      );
    });

    test('should create signal from string', () {
      const signal = Signal.string('signal string');

      signal.when(
        data: (_) => fail('Should be string type'),
        string: (str) => expect(str, equals('signal string')),
      );
    });
  });

  group('ReusableOffer', () {
    test('should create instance with sdp and offerId', () {
      const offer = ReusableOffer(
        sdp: 'offer sdp content',
        offerId: 'offer-123',
      );

      expect(offer.sdp, equals('offer sdp content'));
      expect(offer.offerId, equals('offer-123'));
    });

    test('should serialize and deserialize', () {
      const offer = ReusableOffer(
        sdp: 'test sdp',
        offerId: 'test-id',
      );

      final json = offer.toJson();
      final restored = ReusableOffer.fromJson(json);

      expect(restored.sdp, equals(offer.sdp));
      expect(restored.offerId, equals(offer.offerId));
    });
  });

  group('ReusableAnswer', () {
    test('should create instance with all required fields', () {
      const answer = ReusableAnswer(
        answerId: 'answer-123',
        connectionId: 'conn-456',
        offerId: 'offer-789',
        targetPeer: 'peer-abc',
      );

      expect(answer.answerId, equals('answer-123'));
      expect(answer.connectionId, equals('conn-456'));
      expect(answer.offerId, equals('offer-789'));
      expect(answer.targetPeer, equals('peer-abc'));
    });

    test('should serialize and deserialize', () {
      const answer = ReusableAnswer(
        answerId: 'ans-1',
        connectionId: 'conn-1',
        offerId: 'off-1',
        targetPeer: 'peer-1',
      );

      final json = answer.toJson();
      final restored = ReusableAnswer.fromJson(json);

      expect(restored.answerId, equals(answer.answerId));
      expect(restored.connectionId, equals(answer.connectionId));
      expect(restored.offerId, equals(answer.offerId));
      expect(restored.targetPeer, equals(answer.targetPeer));
    });
  });

  group('Response', () {
    test('should create instance with connectionId', () {
      const response = Response(
        connectionId: 'conn-123',
      );

      expect(response.connectionId, equals('conn-123'));
      expect(response.peer, isNull);
    });

    test('should support peer object', () {
      const response = Response(
        connectionId: 'conn-123',
        peer: 'mock-peer',
      );

      expect(response.connectionId, equals('conn-123'));
      expect(response.peer, equals('mock-peer'));
    });
  });

  group('OfferResponse', () {
    test('should create instance with answer', () {
      const answer = SignalInfoAnswer(
        signalData: SignalData(type: 'answer', sdp: 'sdp'),
        reusableAnswer: ReusableAnswer(
          answerId: 'ans-1',
          connectionId: 'conn-1',
          offerId: 'off-1',
          targetPeer: 'peer-1',
        ),
      );

      const response = OfferResponse(
        connectionId: 'conn-123',
        answer: answer,
      );

      expect(response.connectionId, equals('conn-123'));
      expect(response.answer, equals(answer));
      expect(response.peer, isNull);
    });
  });

  group('AnswerResponse', () {
    test('should create instance with remotePeerId', () {
      const response = AnswerResponse(
        connectionId: 'conn-123',
        remotePeerId: 'peer-456',
      );

      expect(response.connectionId, equals('conn-123'));
      expect(response.remotePeerId, equals('peer-456'));
      expect(response.peer, isNull);
    });
  });

  group('SignalInfoOffer', () {
    test('should create instance with signal data and reusable offer', () {
      const offer = SignalInfoOffer(
        signalData: SignalData(type: 'offer', sdp: 'offer sdp'),
        reusableOffer: ReusableOffer(
          sdp: 'offer sdp',
          offerId: 'offer-1',
        ),
      );

      expect(offer.signalData.type, equals('offer'));
      expect(offer.reusableOffer.offerId, equals('offer-1'));
    });

    test('isOffer should return true', () {
      const offer = SignalInfoOffer(
        signalData: SignalData(type: 'offer', sdp: 'sdp'),
        reusableOffer: ReusableOffer(sdp: 'sdp', offerId: 'id'),
      );

      expect(offer.isOffer(), isTrue);
      expect(offer.isAnswer(), isFalse);
    });

    test('getSignalData should return signal data', () {
      const signalData = SignalData(type: 'offer', sdp: 'sdp');
      const offer = SignalInfoOffer(
        signalData: signalData,
        reusableOffer: ReusableOffer(sdp: 'sdp', offerId: 'id'),
      );

      expect(offer.getSignalData(), equals(signalData));
    });

    test('getOfferInfo should return reusable offer', () {
      const reusableOffer = ReusableOffer(sdp: 'sdp', offerId: 'id');
      const offer = SignalInfoOffer(
        signalData: SignalData(type: 'offer', sdp: 'sdp'),
        reusableOffer: reusableOffer,
      );

      expect(offer.getOfferInfo(), equals(reusableOffer));
    });

    test('should serialize and deserialize', () {
      const offer = SignalInfoOffer(
        signalData: SignalData(type: 'offer', sdp: 'test sdp'),
        reusableOffer: ReusableOffer(sdp: 'test sdp', offerId: 'test-id'),
      );

      final json = offer.toJson();
      final restored = SignalInfoOffer.fromJson(json);

      expect(
        restored.signalData.type,
        equals(offer.signalData.type),
      );
      expect(
        restored.reusableOffer.offerId,
        equals(offer.reusableOffer.offerId),
      );
    });
  });

  group('SignalInfoAnswer', () {
    test('should create instance with signal data and reusable answer', () {
      const answer = SignalInfoAnswer(
        signalData: SignalData(type: 'answer', sdp: 'answer sdp'),
        reusableAnswer: ReusableAnswer(
          answerId: 'ans-1',
          connectionId: 'conn-1',
          offerId: 'off-1',
          targetPeer: 'peer-1',
        ),
      );

      expect(answer.signalData.type, equals('answer'));
      expect(answer.reusableAnswer.answerId, equals('ans-1'));
    });

    test('isAnswer should return true', () {
      const answer = SignalInfoAnswer(
        signalData: SignalData(type: 'answer', sdp: 'sdp'),
        reusableAnswer: ReusableAnswer(
          answerId: 'ans',
          connectionId: 'conn',
          offerId: 'off',
          targetPeer: 'peer',
        ),
      );

      expect(answer.isAnswer(), isTrue);
      expect(answer.isOffer(), isFalse);
    });

    test('getSignalData should return signal data', () {
      const signalData = SignalData(type: 'answer', sdp: 'sdp');
      const answer = SignalInfoAnswer(
        signalData: signalData,
        reusableAnswer: ReusableAnswer(
          answerId: 'ans',
          connectionId: 'conn',
          offerId: 'off',
          targetPeer: 'peer',
        ),
      );

      expect(answer.getSignalData(), equals(signalData));
    });

    test('getAnswerInfo should return reusable answer', () {
      const reusableAnswer = ReusableAnswer(
        answerId: 'ans',
        connectionId: 'conn',
        offerId: 'off',
        targetPeer: 'peer',
      );
      const answer = SignalInfoAnswer(
        signalData: SignalData(type: 'answer', sdp: 'sdp'),
        reusableAnswer: reusableAnswer,
      );

      expect(answer.getAnswerInfo(), equals(reusableAnswer));
    });

    test('should serialize and deserialize', () {
      const answer = SignalInfoAnswer(
        signalData: SignalData(type: 'answer', sdp: 'test sdp'),
        reusableAnswer: ReusableAnswer(
          answerId: 'test-ans',
          connectionId: 'test-conn',
          offerId: 'test-off',
          targetPeer: 'test-peer',
        ),
      );

      final json = answer.toJson();
      final restored = SignalInfoAnswer.fromJson(json);

      expect(
        restored.signalData.type,
        equals(answer.signalData.type),
      );
      expect(
        restored.reusableAnswer.answerId,
        equals(answer.reusableAnswer.answerId),
      );
    });
  });

  group('SignalInfo', () {
    test('should create offer type', () {
      const signalInfo = SignalInfo.offer(
        SignalInfoOffer(
          signalData: SignalData(type: 'offer', sdp: 'sdp'),
          reusableOffer: ReusableOffer(sdp: 'sdp', offerId: 'id'),
        ),
      );

      signalInfo.when(
        offer: (offer) => expect(offer.isOffer(), isTrue),
        answer: (_) => fail('Should be offer type'),
      );
    });

    test('should create answer type', () {
      const signalInfo = SignalInfo.answer(
        SignalInfoAnswer(
          signalData: SignalData(type: 'answer', sdp: 'sdp'),
          reusableAnswer: ReusableAnswer(
            answerId: 'ans',
            connectionId: 'conn',
            offerId: 'off',
            targetPeer: 'peer',
          ),
        ),
      );

      signalInfo.when(
        offer: (_) => fail('Should be answer type'),
        answer: (answer) => expect(answer.isAnswer(), isTrue),
      );
    });
  });
}
