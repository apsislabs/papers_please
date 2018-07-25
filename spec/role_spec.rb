require 'spec_helper'

RSpec.describe PapersPlease::Role do

    describe '#applies_to?' do
        let(:admin_user) { User.new(posts: [], admin: true, member: false) }
        let(:member_user) { User.new(posts: [], admin: false, member: true) }

        context 'no predicate' do
            let(:no_predicate_role) { PapersPlease::Role.new(:admin) }
            it 'applies' do
                expect(no_predicate_role.applies_to?(member_user)).to be true
            end
        end

        context 'predicate' do
            let(:admin_role) { PapersPlease::Role.new(:admin, predicate: (proc { |user| user.admin? })) }

            it 'applies to admin' do
                expect(admin_role.applies_to?(admin_user)).to be true
            end

            it 'does not apply to member' do
                expect(admin_role.applies_to?(member_user)).to be false
            end
        end
    end
end