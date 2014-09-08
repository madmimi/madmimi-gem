require 'spec_helper'

describe MadMimi do

  let(:default_mad_mimi) {
    MadMimi.new('test@example.com', 'TEST_API_KEY')
  }

  let(:mad_mimi) {
    default_mad_mimi.tap{ |m| m.raise_exceptions = false }
  }

  context "#initialize" do
    context 'using default settings' do
      subject { MadMimi.new('USERNAME', 'APIKEY') }

      it 'sets username and api key' do
        expect(subject.username).to eq('USERNAME')
        expect(subject.api_key).to  eq('APIKEY')
      end

      it 'sets verify_ssl to true' do
        expect(subject.verify_ssl?).to be_truthy
      end

      it 'sets raise_exceptions to false' do
        expect(subject.raise_exceptions?).to be_falsy
      end
    end

    context 'using custom options' do
      subject { MadMimi.new('USERNAME', 'APIKEY', { raise_exceptions: true, verify_ssl: false }) }

      it 'sets correctly verify_ssl flag' do
        expect(subject.verify_ssl?).to be_falsy
      end

      it 'sets correctly raise_exceptions flag' do
        expect(subject.raise_exceptions?).to be_truthy
      end
    end
  end

  context '#lists', :vcr => { :cassette_name => 'lists' } do
    subject { mad_mimi.lists }

    context 'when there is a single list', :vcr => { :cassette_name => 'lists/single' } do
      it 'returns an array of hashes' do
        expect(subject['lists']['list']).to be_an(Array)
      end
    end

    context 'when there are multiple lists', :vcr => { :cassette_name => 'lists/multiple' } do
      it 'returns an array of hashes' do
        expect(subject['lists']['list']).to be_an(Array)
      end
    end
  end

  context '#memberships', :vcr => { :cassette_name => 'memberships' } do
    subject { mad_mimi.memberships('new_test1@example.com') }

    context 'when there is a single membership', :vcr => { :cassette_name => 'memberships/single' } do
      it 'returns an array of hashes' do
        expect(subject['lists']['list']).to be_an(Array)
      end
    end

    context 'when there are multiple memberships', :vcr => { :cassette_name => 'memberships/multiple' } do
      it 'returns an array of hashes' do
        expect(subject['lists']['list']).to be_an(Array)
      end
    end
  end

  context '#new_list', :vcr => { :cassette_name => 'new_list' } do
    subject { mad_mimi.new_list('new list 1') }

    context 'when there is no such list', :vcr => { :cassette_name => 'new_list/success' } do
      it 'returns a success response' do
        expect(subject['success']).to be_truthy
      end

      it 'creates a new list' do
        VCR.use_cassette('new_list/not_exists') do
          expect(mad_mimi.lists['lists']['list'].any?{ |l| l['name'] == 'new list 1' }).to be_falsy
        end

        subject

        VCR.use_cassette('new_list/exists') do
          expect(mad_mimi.lists['lists']['list'].any?{ |l| l['name'] == 'new list 1' }).to be_truthy
        end
      end
    end

    context 'when there is already the list', :vcr => { :cassette_name => 'new_list/fail' } do
      it 'returns a falsy response' do
        expect(subject['success']).to be_falsy
      end

      it 'returns an error message' do
        expect(subject['error']).to include('already been taken')
      end
    end
  end

  context '#delete_list', :vcr => { :cassette_name => 'delete_list' } do
    subject { mad_mimi.delete_list('new list 1') }

    context 'when list exists', :vcr => { :cassette_name => 'delete_list/success' } do
      it 'returns an empty response' do
        expect(subject).to eq(' ')
      end

      it 'deletes the list' do
        VCR.use_cassette('delete_list/exists') do
          expect(mad_mimi.lists['lists']['list'].any?{ |l| l['name'] == 'new list 1' }).to be_truthy
        end

        subject

        VCR.use_cassette('delete_list/not_exists') do
          expect(mad_mimi.lists['lists']['list'].any?{ |l| l['name'] == 'new list 1' }).to be_falsy
        end
      end
    end

    context 'when list does not exist', :vcr => { :cassette_name => 'delete_list/fail' } do
      it 'returns an empty response' do
        expect(subject).to eq(' ')
      end
    end
  end

  context '#csv_import', :vcr => { :cassette_name => 'csv_import/success' } do
    subject { mad_mimi.csv_import("email,firstname,lastname\ncsv_test@example.com,test,csv\ncsv_test2@example.com,test2,csv2\n") }

    it 'returns an id of import' do
      expect(subject).to be_present
      expect(subject.to_i).to be > 0
    end

    it 'imports the list' do
      VCR.use_cassette('csv_import/users_missing') do
        expect(mad_mimi.members['audience']['member'].any?{ |m| m['email'] == 'csv_test@example.com' }).to be_falsy
        expect(mad_mimi.members['audience']['member'].any?{ |m| m['email'] == 'csv_test2@example.com' }).to be_falsy
      end

      subject

      VCR.use_cassette('csv_import/users_exist') do
        expect(mad_mimi.members['audience']['member'].any?{ |m| m['email'] == 'csv_test@example.com' }).to be_truthy
        expect(mad_mimi.members['audience']['member'].any?{ |m| m['email'] == 'csv_test2@example.com' }).to be_truthy
      end
    end
  end

  context '#add_user' do
    subject {
      mad_mimi.add_user({
        :email => 'add_user@example.com',
        :firstname => 'AddUser',
        :custom_value_1 => 'add_user'
      })
    }

    context 'when user does not exist', :vcr => { :cassette_name => 'add_user/user_did_not_exist' } do
      it 'returns an id of import' do
        expect(subject).to be_present
        expect(subject.to_i).to be > 0
      end

      it 'creates a user' do
        VCR.use_cassette('add_user/user_missing') do
          expect(mad_mimi.members['audience']['member'].any?{ |m|
            m['email']          == 'add_user@example.com' &&
            m['first_name']     == 'AddUser' &&
            m['custom_value_1'] == 'add_user'
          }).to be_falsy
        end

        subject

        VCR.use_cassette('add_user/user_exist') do
          expect(mad_mimi.members['audience']['member'].any?{ |m|
            m['email']          == 'add_user@example.com' &&
            m['first_name']     == 'AddUser' &&
            m['custom_value_1'] == 'add_user'
          }).to be_truthy
        end
      end
    end

    context 'when user exists', :vcr => { :cassette_name => 'add_user/user_existed' } do
      subject {
        mad_mimi.add_user({
          :email => 'add_user@example.com',
          :firstname => 'AddUser',
          :custom_value_1 => 'updated'
        })
      }

      it 'returns an id of import' do
        expect(subject).to be_present
        expect(subject.to_i).to be > 0
      end

      it 'updates user' do
        VCR.use_cassette('add_user/user_exist') do
          member = mad_mimi.members['audience']['member'].select{ |m|
            m['email']          == 'add_user@example.com' &&
            m['first_name']     == 'AddUser'
          }.first

          expect(member).to be_present
          expect(member['custom_value_1']).to eq('add_user')
        end

        subject

        VCR.use_cassette('add_user/user_updated') do
          member = mad_mimi.members['audience']['member'].select{ |m|
            m['email']          == 'add_user@example.com' &&
            m['first_name']     == 'AddUser'
          }.first

          expect(member).to be_present
          expect(member['custom_value_1']).to eq('updated')
        end
      end
    end
  end

  context '#add_users' do
    subject {
      mad_mimi.add_users([
        {
          :email => 'add_users1@example.com',
          :firstname => 'AddUsers1',
          :custom_value_1 => 'add_users1'
        },
        {
          :email => 'add_users2@example.com',
          :firstname => 'AddUsers2',
          :custom_value_2 => 'add_users2'
        }
      ])
    }

    context 'when user does not exist', :vcr => { :cassette_name => 'add_users/users_did_not_exist' } do
      it 'returns an id of import' do
        expect(subject).to be_present
        expect(subject.to_i).to be > 0
      end

      it 'creates users' do
        VCR.use_cassette('add_users/users_missing') do
          expect(mad_mimi.members['audience']['member'].any?{ |m|
            m['email']          == 'add_users1@example.com' &&
            m['first_name']     == 'AddUsers1' &&
            m['custom_value_1'] == 'add_users1'
          }).to be_falsy

          expect(mad_mimi.members['audience']['member'].any?{ |m|
            m['email']          == 'add_users2@example.com' &&
            m['first_name']     == 'AddUsers2' &&
            m['custom_value_2'] == 'add_users2'
          }).to be_falsy
        end

        subject

        VCR.use_cassette('add_users/users_exist') do
          expect(mad_mimi.members['audience']['member'].any?{ |m|
            m['email']          == 'add_users1@example.com' &&
            m['first_name']     == 'AddUsers1' &&
            m['custom_value_1'] == 'add_users1'
          }).to be_truthy

          expect(mad_mimi.members['audience']['member'].any?{ |m|
            m['email']          == 'add_users2@example.com' &&
            m['first_name']     == 'AddUsers2' &&
            m['custom_value_2'] == 'add_users2'
          }).to be_truthy
        end
      end
    end

    context 'when users exist', :vcr => { :cassette_name => 'add_users/users_existed' } do
      subject {
        mad_mimi.add_users([
          {
            :email => 'add_users1@example.com',
            :firstname => 'AddUsers1',
            :custom_value_1 => 'updated1'
          },
          {
            :email => 'add_users2@example.com',
            :firstname => 'AddUsers2',
            :custom_value_2 => 'updated2'
          }
        ])
      }

      it 'returns an id of import' do
        expect(subject).to be_present
        expect(subject.to_i).to be > 0
      end

      it 'updates user' do
        VCR.use_cassette('add_users/users_exist') do
          member1 = mad_mimi.members['audience']['member'].select{ |m|
            m['email']          == 'add_users1@example.com' &&
            m['first_name']     == 'AddUsers1'
          }.first

          expect(member1).to be_present
          expect(member1['custom_value_1']).to eq('add_users1')

          member2 = mad_mimi.members['audience']['member'].select{ |m|
            m['email']          == 'add_users2@example.com' &&
            m['first_name']     == 'AddUsers2'
          }.first

          expect(member2).to be_present
          expect(member2['custom_value_2']).to eq('add_users2')
        end

        subject

        VCR.use_cassette('add_users/users_updated') do
          member1 = mad_mimi.members['audience']['member'].select{ |m|
            m['email']          == 'add_users1@example.com' &&
            m['first_name']     == 'AddUsers1'
          }.first

          expect(member1).to be_present
          expect(member1['custom_value_1']).to eq('updated1')

          member2 = mad_mimi.members['audience']['member'].select{ |m|
            m['email']          == 'add_users2@example.com' &&
            m['first_name']     == 'AddUsers2'
          }.first

          expect(member2).to be_present
          expect(member2['custom_value_2']).to eq('updated2')
        end
      end
    end
  end

  context '#add_to_list' do
    subject { mad_mimi.add_to_list('test@example.com', 'list 1', { :custom_value => 'new value' }) }

    context 'when user does not exist', :vcr => { :cassette_name => 'add_to_list/success' } do
      it "creates user" do
        VCR.use_cassette('add_to_list/user_does_not_exist') do
          expect(mad_mimi.members['audience']['member'].any?{ |m| m['email'] == 'test@example.com' }).to be_falsy
        end

        subject

        VCR.use_cassette('add_to_list/user_exists') do
          expect(mad_mimi.members['audience']['member'].any?{ |m| m['email'] == 'test@example.com' }).to be_truthy
        end
      end
    end

    context 'when user exists', :vcr => { :cassette_name => 'add_to_list/user_existed'} do
      subject { mad_mimi.add_to_list('test@example.com', 'list 1', { :custom_value => 'updated value' }) }

      it "updates user" do
        VCR.use_cassette('add_to_list/user_exists') do
          member = mad_mimi.members['audience']['member'].select{ |m| m['email'] == 'test@example.com' }.first
          expect(member['custom_value']).to eq('new value')
        end

        subject

        VCR.use_cassette('add_to_list/user_updated') do
          member = mad_mimi.members['audience']['member'].select{ |m| m['email'] == 'test@example.com' }.first
          expect(member['custom_value']).to eq('updated value')
        end
      end
    end
  end

  context '#remove_from_list' do
    subject { mad_mimi.remove_from_list('test@example.com', 'list 1') }

    context 'when user is in the list', :vcr => { :cassette_name => 'remove_from_list/user_in_the_list' } do
      it "returns empty response" do
        expect(subject).to be_nil
      end

      it "removes user from list" do
        VCR.use_cassette('remove_from_list/user_in_list_exists') do
          expect(mad_mimi.list_members('list 1')['audience']['member'].any?{ |m| m['email'] == 'test@example.com' }).to be_truthy
        end

        subject

        VCR.use_cassette('remove_from_list/user_in_list_does_not_exist') do
          expect(mad_mimi.list_members('list 1')['audience']['member'].any?{ |m| m['email'] == 'test@example.com' }).to be_falsy
        end
      end
    end

    context 'when user is not in the list', :vcr => { :cassette_name => 'remove_from_list/user_not_in_the_list' } do
      it "returns empty response" do
        expect(subject).to be_nil
      end
    end

    context 'when user does not exist', :vcr => { :cassette_name => 'remove_from_list/user_does_not_exist' } do
      subject { mad_mimi.remove_from_list('wrong@example.com', 'list 1') }

      it "returns empty response" do
        expect(subject).to be_nil
      end
    end
  end

  context '#remove_from_all_lists' do
    subject { mad_mimi.remove_from_all_lists('test@example.com') }

    context 'when user has memberships', :vcr => { :cassette_name => 'remove_from_all_lists/user_with_memberships' } do
      it "removes user from all lists" do
        VCR.use_cassette('remove_from_all_lists/user_has_memberships') do
          expect(mad_mimi.memberships('test@example.com')['lists']['list']).not_to be_empty
        end

        subject

        VCR.use_cassette('remove_from_all_list/user_does_not_have_memberships') do
          expect(mad_mimi.memberships('test@example.com')['lists']).to be_nil
        end
      end
    end
  end

  context '#update_email' do
    subject { mad_mimi.update_email('test@example.com', 'updated@example.com') }

    context 'when user has permission' do
      context 'when user exists', :vcr => { :cassette_name => 'update_email/user_existed' } do
        it "updates email" do
          VCR.use_cassette('update_email/user_with_old_email') do
            expect(mad_mimi.members['audience']['member'].any?{ |m| m['email'] == 'test@example.com' }).to be_truthy
            expect(mad_mimi.members['audience']['member'].any?{ |m| m['email'] == 'updated@example.com' }).to be_falsy
          end

          subject

          VCR.use_cassette('update_email/user_with_new_email') do
            expect(mad_mimi.members['audience']['member'].any?{ |m| m['email'] == 'test@example.com' }).to be_falsy
            expect(mad_mimi.members['audience']['member'].any?{ |m| m['email'] == 'updated@example.com' }).to be_truthy
          end
        end
      end

      context 'when user does not exist', :vcr => { :cassette_name => 'update_email/user_missing' } do
        it "returns empty response" do
          expect(subject).to include('does not exist')
        end
      end
    end

    context 'when user does not have permission', :vcr => { :cassette_name => 'update_email/user_does_not_have_permission' } do
      context 'if should raise exception' do
        before(:each) { mad_mimi.raise_exceptions = true }

        it "raises an error" do
          expect{ subject }.to raise_error(Net::HTTPServerException)
        end
      end

      context 'if should not raise exception' do
        before(:each) { mad_mimi.raise_exceptions = false }

        it "returns an error" do
          expect(subject).to eq('You do not have the rights to use this API')
        end
      end
    end
  end

  context '#members' do
    subject { mad_mimi.members }

    context 'when there is only one member', :vcr => { :cassette_name => 'members/single' } do
      it 'returns count equal to one' do
        expect(subject['audience']['count'].to_i).to eq(1)
      end

      it 'returns an array of hashes' do
        expect(subject['audience']['member']).to be_an(Array)
      end
    end

    context 'when there are multiple members', :vcr => { :cassette_name => 'members/multiple' } do
      it 'returns count greater than one' do
        expect(subject['audience']['count'].to_i).to be > 1
      end

      it 'returns an array of hashes' do
        expect(subject['audience']['member']).to be_an(Array)
      end
    end
  end

  context '#list_members' do
    subject { mad_mimi.list_members('list 1') }

    context 'when there is only one member', :vcr => { :cassette_name => 'list_members/single' } do
      it 'returns count equal to one' do
        expect(subject['audience']['count'].to_i).to eq(1)
      end

      it 'returns an array of hashes' do
        expect(subject['audience']['member']).to be_an(Array)
      end
    end

    context 'when there are multiple members', :vcr => { :cassette_name => 'list_members/multiple' } do
      it 'returns count greater than one' do
        expect(subject['audience']['count'].to_i).to be > 1
      end

      it 'returns an array of hashes' do
        expect(subject['audience']['member']).to be_an(Array)
      end
    end
  end

  context '#suppressed_since' do
    subject { mad_mimi.suppressed_since(1409512823) }

    context 'when there is no suppressed members', :vcr => { :cassette_name => 'suppressed_since/no_members' } do
      it 'returns an empty response' do
        expect(subject).to eq("\n")
      end
    end

    context 'when there are suppressed members', :vcr => { :cassette_name => 'suppressed_since/members_exist' } do
      it 'returns an email' do
        expect(subject).to include("new_test1@example.com")
      end
    end
  end

  context '#suppress_email' do
    subject { mad_mimi.suppress_email('test@example.com') }

    context 'when user is already suppressed', :vcr => { :cassette_name => 'suppress_email/already_suppressed' } do
      it 'user is suppressed' do
        expect(mad_mimi.suppressed?('test@example.com')).to be_truthy
      end

      it 'returns empty response' do
        expect(subject).to eq('')
      end
    end

    context 'when user is not suppressed', :vcr => { :cassette_name => 'suppress_email/not_suppressed' } do
      it 'user is not suppressed' do
        expect(mad_mimi.suppressed?('test@example.com')).to be_falsy
      end

      it 'suppresses user' do
        VCR.use_cassette('suppress_email/user_not_suppressed') do
          expect(mad_mimi.suppressed?('test@example.com')).to be_falsy
        end

        subject

        VCR.use_cassette('suppress_email/user_is_now_suppressed') do
          expect(mad_mimi.suppressed?('test@example.com')).to be_truthy
        end
      end
    end

    context 'when user does not exist', :vcr => { :cassette_name => 'suppress_email/user_does_not_exist' } do
      it 'returns an error' do
        expect(subject).to include("Couldn't find AudienceMember")
      end
    end
  end

  context '#unsuppress_email' do
    subject { mad_mimi.unsuppress_email('test@example.com') }

    context 'when user is already suppressed', :vcr => { :cassette_name => 'unsuppress_email/already_suppressed' } do
      it 'user is suppressed' do
        expect(mad_mimi.suppressed?('test@example.com')).to be_truthy
      end

      it 'returns empty response' do
        expect(subject).to eq('')
      end
    end

    context 'when user is not suppressed', :vcr => { :cassette_name => 'unsuppress_email/not_suppressed' } do
      it 'suppresses user' do
        VCR.use_cassette('unsuppress_email/user_suppressed') do
          expect(mad_mimi.suppressed?('test@example.com')).to be_truthy
        end

        subject

        VCR.use_cassette('unsuppress_email/user_is_now_unsuppressed') do
          expect(mad_mimi.suppressed?('test@example.com')).to be_falsy
        end
      end
    end

    context 'when user does not exist', :vcr => { :cassette_name => 'unsuppress_email/user_does_not_exist' } do
      it 'returns an empty response' do
        expect(subject).to eq('')
      end
    end
  end

  context '#suppressed?' do
    subject { mad_mimi.suppressed?('test@example.com') }

    context 'when user is suppressed', :vcr => { :cassette_name => 'suppressed/member_is_suppressed' } do
      it 'returns true' do
        expect(subject).to be_truthy
      end
    end

    context 'when user is not suppressed', :vcr => { :cassette_name => 'suppressed/member_is_not_suppressed' } do
      it 'returns false' do
        expect(subject).to be_falsy
      end
    end

    context 'when user does not exist', :vcr => { :cassette_name => 'suppressed/member_does_not_exist' } do
      it 'returns false' do
        expect(subject).to be_falsy
      end
    end
  end

  context '#audience_search' do
    context 'when does not include suppressed users', :vcr => { :cassette_name => 'audience_search/does_not_include_suppressed_users' } do
      subject { mad_mimi.audience_search('test', false) }

      it 'returns array' do
        expect(subject['audience']['member']).to be_an(Array)
      end

      it 'does not include suppressed member' do
        expect(subject['audience']['member'].any?{ |m| m['email'] == 'test@example.com' }).to be_falsy
      end
    end

    context 'when includes suppressed users', :vcr => { :cassette_name => 'audience_search/includes_suppressed_users' } do
      subject { mad_mimi.audience_search('test', true) }

      it 'returns array' do
        expect(subject['audience']['member']).to be_an(Array)
      end

      it 'includes suppressed member' do
        expect(subject['audience']['member'].any?{ |m| m['email'] == 'test@example.com' }).to be_truthy
      end
    end
  end

  context '#add_users_to_list' do
    subject {
      mad_mimi.add_users_to_list('list 1', [
        { :email => 'add_users_to_list1@example.com' },
        { :email => 'add_users_to_list2@example.com' }
      ])
    }

    context 'when user does not exist', :vcr => { :cassette_name => 'add_users_to_list/users_did_not_exist' } do
      it 'returns an id of import' do
        expect(subject).to be_present
        expect(subject.to_i).to be > 0
      end

      it 'creates users' do
        VCR.use_cassette('add_users_to_list/users_missing') do
          expect(mad_mimi.members['audience']['member'].any?{ |m| m['email'] == 'add_users_to_list1@example.com' }).to be_falsy
          expect(mad_mimi.members['audience']['member'].any?{ |m| m['email'] == 'add_users_to_list2@example.com' }).to be_falsy
        end

        subject

        VCR.use_cassette('add_users_to_list/users_exist') do
          expect(mad_mimi.members['audience']['member'].any?{ |m| m['email'] == 'add_users_to_list1@example.com' }).to be_truthy
          expect(mad_mimi.members['audience']['member'].any?{ |m| m['email'] == 'add_users_to_list2@example.com' }).to be_truthy
        end
      end

      it 'adds users to the list' do
        VCR.use_cassette('add_users_to_list/missing_membership') do
          expect(mad_mimi.memberships('add_users_to_list1@example.com')['lists']).to be_nil
          expect(mad_mimi.memberships('add_users_to_list2@example.com')['lists']).to be_nil
        end

        subject

        VCR.use_cassette('add_users_to_list/gained_membership') do
          expect(mad_mimi.memberships('add_users_to_list1@example.com')['lists']['list'].any?{ |l| l['name'] == 'list 1' }).to be_truthy
          expect(mad_mimi.memberships('add_users_to_list2@example.com')['lists']['list'].any?{ |l| l['name'] == 'list 1' }).to be_truthy
        end
      end
    end

    context 'when users exist', :vcr => { :cassette_name => 'add_users_to_list/users_existed' } do
      subject {
        mad_mimi.add_users_to_list('list 1', [
          { :email => 'add_users_to_list1@example.com', :first_name => 'First' },
          { :email => 'add_users_to_list2@example.com', :first_name => 'Second' }
        ])
      }

      it 'returns an id of import' do
        expect(subject).to be_present
        expect(subject.to_i).to be > 0
      end

      it 'updates user' do
        VCR.use_cassette('add_users_to_list/users_exist') do
          member1 = mad_mimi.members['audience']['member'].select{ |m|
            m['email'] == 'add_users_to_list1@example.com'
          }.first

          expect(member1).to be_present
          expect(member1['first_name']).to be_nil

          member2 = mad_mimi.members['audience']['member'].select{ |m|
            m['email'] == 'add_users_to_list2@example.com'
          }.first

          expect(member2).to be_present
          expect(member2['first_name']).to be_nil
        end

        subject

        VCR.use_cassette('add_users_to_list/users_updated') do
          member1 = mad_mimi.members['audience']['member'].select{ |m|
            m['email']          == 'add_users_to_list1@example.com'
          }.first

          expect(member1).to be_present
          expect(member1['first_name']).to eq('First')

          member2 = mad_mimi.members['audience']['member'].select{ |m|
            m['email']          == 'add_users_to_list2@example.com'
          }.first

          expect(member2).to be_present
          expect(member2['first_name']).to eq('Second')
        end
      end

      it 'adds users to the list' do
        VCR.use_cassette('add_users_to_list/missing_membership') do
          expect(mad_mimi.memberships('add_users_to_list1@example.com')['lists']).to be_nil
          expect(mad_mimi.memberships('add_users_to_list2@example.com')['lists']).to be_nil
        end

        subject

        VCR.use_cassette('add_users_to_list/gained_membership') do
          expect(mad_mimi.memberships('add_users_to_list1@example.com')['lists']['list'].any?{ |l| l['name'] == 'list 1' }).to be_truthy
          expect(mad_mimi.memberships('add_users_to_list2@example.com')['lists']['list'].any?{ |l| l['name'] == 'list 1' }).to be_truthy
        end
      end
    end
  end

  context '#promotions' do
    subject { mad_mimi.promotions }

    context 'when there is a single promotion', :vcr => { :cassette_name => 'promotions/single' } do
      it 'returns an array' do
        expect(subject['promotions']['promotion']).to be_an(Array)
      end
    end

    context 'when there are multiple promotions', :vcr => { :cassette_name => 'promotions/multiple' } do
      it 'returns an array' do
        expect(subject['promotions']['promotion']).to be_an(Array)
      end
    end
  end

  context '#save_promotion' do
    let(:raw_html) { '<html><body>Test [[tracking_beacon]][[opt_out]]</body></html>' }
    let(:plain_text) { 'Test [[opt_out]]' }

    subject {
      mad_mimi.save_promotion(
        'Test promotion',
        raw_html,
        plain_text
      )
    }

    context 'when only raw_html specified', :vcr => { :cassette_name => 'save_promotion/only_raw_html' } do
      let(:plain_text) { nil }

      context 'when tracking beacon and opt out are present' do
        it 'saves promotions' do
          VCR.use_cassette('save_promotion/promotion_missing') do
            expect(mad_mimi.promotions['promotions']['promotion'].any?{ |p| p['name'] == 'Test promotion' }).to be_falsy
          end

          subject

          VCR.use_cassette('save_promotion/promotion_exists') do
            expect(mad_mimi.promotions['promotions']['promotion'].any?{ |p| p['name'] == 'Test promotion' }).to be_truthy
          end
        end

        it 'returns success response' do
          expect(subject).to include('Saved Test promotion')
        end
      end

      context 'when tracking beacon is missing' do
        let(:raw_html) { '<html><body>Test [[opt_out]]</body></html>' }

        it 'raises a MadMimiError' do
          expect{ subject }.to raise_error(MadMimi::MadMimiError)
        end
      end

      context 'when opt out is missing' do
        let(:raw_html) { '<html><body>Test [[tracking_beacon]]</body></html>' }

        it 'raises a MadMimiError' do
          expect{ subject }.to raise_error(MadMimi::MadMimiError)
        end
      end
    end

    context 'when only plain_text specified', :vcr => { :cassette_name => 'save_promotion/only_plain_text' } do
      let(:raw_html) { nil }

      context 'when opt out is present' do
        it 'saves promotions' do
          VCR.use_cassette('save_promotion/promotion_missing') do
            expect(mad_mimi.promotions['promotions']['promotion'].any?{ |p| p['name'] == 'Test promotion' }).to be_falsy
          end

          subject

          VCR.use_cassette('save_promotion/promotion_exists') do
            expect(mad_mimi.promotions['promotions']['promotion'].any?{ |p| p['name'] == 'Test promotion' }).to be_truthy
          end
        end

        it 'returns success response' do
          expect(subject).to include('Saved Test promotion')
        end
      end

      context 'when opt out is missing' do
        let(:plain_text) { 'Test' }

        it 'raises a MadMimiError' do
          expect{ subject }.to raise_error(MadMimi::MadMimiError)
        end
      end
    end

    context 'when both raw_html and plain_text are specified', :vcr => { :cassette_name => 'save_promotion/raw_html_and_plain_text' } do
      it 'saves promotions' do
        VCR.use_cassette('save_promotion/promotion_missing') do
          expect(mad_mimi.promotions['promotions']['promotion'].any?{ |p| p['name'] == 'Test promotion' }).to be_falsy
        end

        subject

        VCR.use_cassette('save_promotion/promotion_exists') do
          expect(mad_mimi.promotions['promotions']['promotion'].any?{ |p| p['name'] == 'Test promotion' }).to be_truthy
        end
      end

      it 'returns success response' do
        expect(subject).to include('Saved Test promotion')
      end
    end
  end

  context '#mailing_stats' do
    context 'when promotion and mailing exists', :vcr => { :cassette_name => 'mailing_stats/promotion_and_mailing_exist' } do
      subject { mad_mimi.mailing_stats(5510034, 122026332) }

      it 'returns correct stats' do
        expect(subject['mailing']['untraced']).to eq('1')
      end
    end

    context 'when promotion does not exist', :vcr => { :cassette_name => 'mailing_stats/promotion_does_not_exist' } do
      subject { mad_mimi.mailing_stats(0, 122026332) }

      it 'returns an empty hash' do
        expect(subject).to eq({})
      end
    end

    context 'when promotion does not exist', :vcr => { :cassette_name => 'mailing_stats/mailing_does_not_exist' } do
      subject { mad_mimi.mailing_stats(5510034, 0) }

      it 'returns an empty hash' do
        expect(subject).to eq({})
      end
    end
  end

  context '#send_mail' do
    context 'when options are correct' do
      let(:default_options) {
        {
          :promotion_name => 'Transactional Promotion',
          :from => 'maxim+1@madmimi.com',
          :subject => 'Test'
        }
      }

      context 'when sending to list', :vcr => { :cassette_name => 'send_mail/send_to_list' } do
        subject {
          mad_mimi.send_mail(default_options.merge(:list_name => 'list 1'), {})
        }

        it "returns mailing id" do
          expect(subject).to match(/\d{9}/)
        end
      end

      context 'when sending to all', :vcr => { :cassette_name => 'send_mail/send_to_all' } do
        subject {
          mad_mimi.send_mail(default_options.merge(:to_all => true), {})
        }

        it "returns mailing id" do
          expect(subject).to match(/\d{9}/)
        end
      end

      context 'when sending to single recipient', :vcr => { :cassette_name => 'send_mail/send_single' } do
        subject {
          mad_mimi.send_mail(default_options.merge(:recipient => 'Test Example <test@example.com>'), {})
        }

        it "returns transaction id" do
          expect(subject).to match(/\d{20}/)
        end
      end
    end

    context 'when promotion does not exist', :vcr => { :cassette_name => 'send_mail/promotion_does_not_exist' } do
      subject {
        mad_mimi.send_mail({
          :promotion_name => 'Unknown Promotion',
          :from => 'maxim+1@madmimi.com',
          :subject => 'Test',
          :to_all => true
        }, {})
      }

      it "returns an error" do
        expect(subject).to eq('You do not have a promotion named Unknown Promotion.')
      end
    end
  end

  context '#send_html' do
    let(:raw_html) { '<html><body>Test [[tracking_beacon]] [[opt_out]]</body></html>' }

    context 'when options are correct' do
      let(:default_options) {
        {
          :promotion_name => 'Transactional Promotion',
          :from => 'maxim+1@madmimi.com',
          :subject => 'Test'
        }
      }

      context 'when sending to list', :vcr => { :cassette_name => 'send_html/send_to_list' } do
        subject {
          mad_mimi.send_html(default_options.merge(:list_name => 'list 1'), raw_html)
        }

        it "returns mailing id" do
          expect(subject).to match(/\d{9}/)
        end
      end

      context 'when sending to all', :vcr => { :cassette_name => 'send_html/send_to_all' } do
        subject {
          mad_mimi.send_html(default_options.merge(:to_all => true), raw_html)
        }

        it "returns mailing id" do
          expect(subject).to match(/\d{9}/)
        end
      end

      context 'when sending to single recipient', :vcr => { :cassette_name => 'send_html/send_single' } do
        subject {
          mad_mimi.send_html(default_options.merge(:recipient => 'Test Example <test@example.com>'), raw_html)
        }

        it "returns transaction id" do
          expect(subject).to match(/\d{20}/)
        end
      end
    end

    context 'when promotion does not exist', :vcr => { :cassette_name => 'send_html/promotion_does_not_exist' } do
      subject {
        mad_mimi.send_html({
          :promotion_name => 'Unknown Promotion',
          :from => 'maxim+1@madmimi.com',
          :subject => 'Test',
          :to_all => true
        }, raw_html)
      }

      it "returns mailing id" do
        expect(subject).to match(/\d{9}/)
      end
    end

    context 'when tracking beacon is missing', :vcr => { :cassette_name => 'send_html/tracking_beacon_missing' } do
      let(:raw_html) { '<html><body>Test [[opt_out]]</body></html>' }

      subject {
        mad_mimi.send_html({
          :promotion_name => 'Unknown Promotion',
          :from => 'maxim+1@madmimi.com',
          :subject => 'Test',
          :to_all => true
        }, raw_html)
      }

      it "raises MadMimiError" do
        expect{ subject }.to raise_error(MadMimi::MadMimiError)
      end
    end

    context 'when opt_out is missing', :vcr => { :cassette_name => 'send_html/opt_out_missing' } do
      let(:raw_html) { '<html><body>Test [[tracking_beacon]]</body></html>' }

      subject {
        mad_mimi.send_html({
          :promotion_name => 'Unknown Promotion',
          :from => 'maxim+1@madmimi.com',
          :subject => 'Test',
          :to_all => true
        }, raw_html)
      }

      it "raises MadMimiError" do
        expect{ subject }.to raise_error(MadMimi::MadMimiError)
      end
    end
  end

  context '#send_plaintext' do
    let(:plain_text) { 'Test [[tracking_beacon]] [[opt_out]]' }

    context 'when options are correct' do
      let(:default_options) {
        {
          :promotion_name => 'Transactional Promotion',
          :from => 'maxim+1@madmimi.com',
          :subject => 'Test'
        }
      }

      context 'when sending to list', :vcr => { :cassette_name => 'send_plaintext/send_to_list' } do
        subject {
          mad_mimi.send_plaintext(default_options.merge(:list_name => 'list 1'), plain_text)
        }

        it "returns mailing id" do
          expect(subject).to match(/\d{9}/)
        end
      end

      context 'when sending to all', :vcr => { :cassette_name => 'send_plaintext/send_to_all' } do
        subject {
          mad_mimi.send_plaintext(default_options.merge(:to_all => true), plain_text)
        }

        it "returns mailing id" do
          expect(subject).to match(/\d{9}/)
        end
      end

      context 'when sending to single recipient', :vcr => { :cassette_name => 'send_plaintext/send_single' } do
        subject {
          mad_mimi.send_plaintext(default_options.merge(:recipient => 'Test Example <test@example.com>'), plain_text)
        }

        it "returns transaction id" do
          expect(subject).to match(/\d{20}/)
        end
      end
    end

    context 'when promotion does not exist', :vcr => { :cassette_name => 'send_plaintext/promotion_does_not_exist' } do
      subject {
        mad_mimi.send_plaintext({
          :promotion_name => 'Unknown Promotion',
          :from => 'maxim+1@madmimi.com',
          :subject => 'Test',
          :to_all => true
        }, plain_text)
      }

      it "returns mailing id" do
        expect(subject).to match(/\d{9}/)
      end
    end

    context 'when opt_out is missing', :vcr => { :cassette_name => 'send_plaintext/opt_out_missing' } do
      let(:plain_text) { 'Test [[tracking_beacon]]' }

      subject {
        mad_mimi.send_html({
          :promotion_name => 'Unknown Promotion',
          :from => 'maxim+1@madmimi.com',
          :subject => 'Test',
          :to_all => true
        }, plain_text)
      }

      it "raises MadMimiError" do
        expect{ subject }.to raise_error(MadMimi::MadMimiError)
      end
    end
  end

  context '#status' do
    context 'when transactional email exists', :vcr => { :cassette_name => 'status/transactional_mail_exists' } do
      subject { mad_mimi.status(10199217171363888473) }

      it 'returns a correct status' do
        expect(subject).to eq('received')
      end
    end

    context 'when transactional email does not exist', :vcr => { :cassette_name => 'status/transactional_mail_does_not_exist' } do
      subject { mad_mimi.status(0) }

      it 'returns an error' do
        expect(subject).to eq('Not Found')
      end
    end
  end

end
