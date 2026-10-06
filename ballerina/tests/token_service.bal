
// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
import ballerina/http;

// Minimal OAuth2 token endpoint used by the mock tests (client credentials grant).
listener http:Listener tokenEp = new (9444);

service /oauth on tokenEp {
    resource function post token() returns json {
        return {
            access_token: "mock-access-token",
            token_type: "bearer",
            expires_in: 3600,
            scope: "view_project_settings:test-project manage_project_settings:test-project"
        };
    }
}
