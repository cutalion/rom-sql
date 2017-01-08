RSpec.describe ROM::Relation, '#left_join' do
  subject(:relation) { relations[:users] }

  let(:tasks) { relations[:tasks] }

  include_context 'users and tasks'

  with_adapters do
    it 'joins relations using left outer join' do
      result = relation.
                 left_join(:tasks, user_id: :id).
                 select(:name, tasks.schema[:title])

      expect(result.schema.map(&:name)).to eql(%i[name title])

      expect(result.to_a).to match_array([
        { name: 'Joe', title: "Joe's task" },
        { name: 'Jane', title: "Jane's task" }
      ])
    end

    context 'with associations' do
      before do
        conf.relation(:users) do
          schema(infer: true) do
            associations { has_many :tasks }
          end
        end

        conf.relation(:tasks) do
          schema(infer: true) do
            associations { belongs_to :user }
          end
        end
      end

      it 'joins relation with join keys inferred' do
        result = relation.
                   left_join(tasks).
                   select(:name, tasks.schema[:title])

        expect(result.schema.map(&:name)).to eql(%i[name title])

        expect(result.to_a).to eql([
                                     { name: 'Jane', title: "Jane's task" },
                                     { name: 'Joe', title: "Joe's task" }
                                   ])
      end
    end
  end
end
