RSpec.describe 'Commands / Postgres / Upsert', adapter: :postgres do
  subject(:command) { commands[:tasks][:create_or_update] }

  include_context 'relations'

  let(:tasks) { commands[:tasks] }

  before do
    conn[:users].insert id: 1, name: 'Jane'
    conn[:users].insert id: 2, name: 'Joe'
    conn[:users].insert id: 3, name: 'Jean'
  end

  describe '#call' do
    let(:task) { { title: 'task 1', user_id: 1 } }
    let(:excluded) { task.merge(user_id: 3) }

    before do
      command_config = self.command_config

      conf.commands(:tasks) do
        define('Postgres::Upsert') do
          register_as :create_or_update
          result :one

          instance_exec(&command_config)
        end
      end
    end

    before { command.relation.upsert(task) }

    context 'on conflict do nothing' do
      let(:command_config) { -> { } }

      it 'returns nil' do
        expect(command.call(excluded)).to be nil
      end
    end

    context 'on conflict do update' do
      context 'with conflict target' do
        let(:command_config) do
          -> do
            conflict_target :title
            update_statement user_id: 2
          end
        end

        it 'returns updated data' do
          expect(command.call(excluded)).to eql(id: 1, user_id: 2, title: 'task 1')
        end
      end

      context 'with constraint name' do
        let(:command_config) do
          -> do
            constraint :tasks_title_key
            update_statement user_id: :excluded__user_id
          end
        end

        it 'returns updated data' do
          expect(command.call(excluded)).to eql(id: 1, user_id: 3, title: 'task 1')
        end
      end

      context 'with where clause' do
        let(:command_config) do
          -> do
            conflict_target :title
            update_statement user_id: nil
            update_where tasks__id: 2
          end
        end

        it 'returns nil' do
          expect(command.call(excluded)).to be nil
        end
      end
    end
  end
end if PG_LTE_95
