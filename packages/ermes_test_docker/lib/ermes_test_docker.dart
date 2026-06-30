// Docker 3-peer mesh test surface. The wire protocol (MessageEnvelope) and
// the OrcErmes bring-up (DockerErmesConfig / createDockerOrcErmes) are shared
// with the NAT tests, so they are re-exported from ermes_test_shared.
export 'package:ermes_test_shared/ermes_test_shared.dart'
    show
        BookData,
        DockerErmesConfig,
        DockerMsgType,
        IOrcErmes,
        MessageEnvelope,
        OrcErmes,
        createDockerOrcErmes;

export 'src/docker_test_runner.dart';
export 'src/result_writer.dart';
export 'src/test_result.dart';
