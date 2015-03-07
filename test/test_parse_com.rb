require 'minitest_helper'

require 'jabara/parse_com'

module ParseComTest
  class TestBuilder < MiniTest::Test
    def test_inner_object_types
      schema = Jabara::ParseCom::Schema::Builder.build do
        type 'test'
        id 'objectId'
        key 'objectId', parse_object_id
        key 'createdAt', timestamp
        key 'statusType', integer
        key 'width', float
        key 'image', file
        key 'ownerId', pointer
        key 'activated', boolean
        key 'metadata', json_string
        key 'options', variants {
          variant key: 'collabo', schema: schema {
            type 'collabo'
            key 'hoge', string
          }
        }
        key 'ACL', acl(user_acl_object_type: 'useracl', role_acl_object_type: 'roleacl')
      end

      assert schema.object_type == 'test'
      assert schema.inner_object_types == ['collabo', 'useracl', 'roleacl']
    end
  end
end
