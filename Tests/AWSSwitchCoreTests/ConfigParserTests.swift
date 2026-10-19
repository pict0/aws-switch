import Foundation
import Testing
@testable import AWSSwitchCore

@Suite struct ConfigParserTests {
    @Test func parsesLegacyAndSessionProfiles() {
        let config = """
            # comment
            [default]
            region = eu-west-2

            [profile platform]
            sso_start_url = https://example.awsapps.com/start
            sso_account_id = 111111111111
            sso_role_name = admin
            region = eu-west-2

            [profile data-prod]
            sso_session = corp
            sso_account_id = 222222222222

            [sso-session corp]
            sso_start_url = https://corp.awsapps.com/start
            """
        let profiles = AWSConfigParser.parse(config)

        #expect(profiles.map(\.name) == ["data-prod", "platform"]) // empty [default] skipped
        #expect(profiles[0].ssoStartURL == "https://corp.awsapps.com/start")
        #expect(profiles[1].accountId == "111111111111")
        #expect(profiles[1].roleName == "admin")
    }
}
