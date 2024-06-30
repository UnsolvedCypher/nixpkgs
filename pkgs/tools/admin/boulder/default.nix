{
  lib,
  fetchFromGitHub,
  buildGoModule,
  testers,
  boulder,
}:

buildGoModule rec {
  pname = "boulder";
  version = "2024-06-25";

  src = fetchFromGitHub {
    owner = "letsencrypt";
    repo = "boulder";
    rev = "release-${version}";
    leaveDotGit = true;
    postFetch = ''
      pushd $out
      git rev-parse --short=8 HEAD 2>/dev/null >$out/COMMIT
      find $out -name .git -print0 | xargs -0 rm -rf
      popd
    '';
    hash = "sha256-AOCYCTIgT9QAn6LR72OG2C8Li1UMFieDrtkplXv4plA=";
  };

  vendorHash = null;

  subPackages = [ "cmd/boulder" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/letsencrypt/boulder/core.BuildHost=nixbld@localhost"
  ];

  preBuild = ''
    ldflags+=" -X \"github.com/letsencrypt/boulder/core.BuildID=${version} +$(cat COMMIT)\""
    ldflags+=" -X \"github.com/letsencrypt/boulder/core.BuildTime=$(date -u -d @0)\""
  '';

  preCheck = ''
    # Test all targets.
    unset subPackages

    # Disable tests that fail or require additional services.
    rm -f \
      cmd/admin-revoker/main_test.go \
      cmd/admin/cert_test.go \
      cmd/admin/key_test.go \
      cmd/bad-key-revoker/main_test.go \
      cmd/cert-checker/main_test.go \
      cmd/config_test.go \
      cmd/contact-auditor/main_test.go \
      cmd/expiration-mailer/main_test.go \
      cmd/expiration-mailer/send_test.go \
      cmd/id-exporter/main_test.go \
      cmd/rocsp-tool/client_test.go \
      cmd/shell_test.go \
      core/util_test.go \
      db/map_test.go \
      db/multi_test.go \
      db/rollback_test.go \
      grpc/creds/creds_test.go \
      log/log_test.go \
      ocsp/updater/updater_test.go \
      ra/ra_test.go \
      ratelimits/limiter_test.go \
      ratelimits/source_redis_test.go \
      ratelimits/source_test.go \
      redis/lookup_test.go \
      rocsp/rocsp_test.go \
      sa/database_test.go \
      sa/model_test.go \
      sa/precertificates_test.go \
      sa/rate_limits_test.go \
      sa/sa_test.go \
      test/load-generator/acme/directory_test.go \
      va/caa_test.go \
      va/dns_test.go \
      va/http_test.go \
      va/tlsalpn_test.go \
      va/va_test.go \
      wfe2/verify_test.go \
      wfe2/wfe_test.go
  '';

  postInstall = ''
    for i in $($out/bin/boulder --list); do
      ln -s $out/bin/boulder $out/bin/$i
    done
  '';

  passthru.tests.version = testers.testVersion {
    package = boulder;
    inherit version;
  };

  meta = with lib; {
    homepage = "https://github.com/letsencrypt/boulder";
    description = "ACME-based certificate authority, written in Go";
    longDescription = ''
      This is an implementation of an ACME-based CA. The ACME protocol allows
      the CA to automatically verify that an applicant for a certificate
      actually controls an identifier, and allows domain holders to issue and
      revoke certificates for their domains. Boulder is the software that runs
      Let's Encrypt.
    '';
    license = licenses.mpl20;
    mainProgram = "boulder";
    maintainers = with maintainers; [ azahi ];
  };
}
