# frozen_string_literal: true

RSpec.describe SimpleLogicStep::Service do
  subject(:perform) { logic_instance.call }

  let(:logic_instance) { logic_class.new(**params) }
  let(:logic_class) { Class.new(described_class, &process_method) }
  let(:some_param) { instance_double('String') }
  let(:params) { { some_param: some_param } }
  let(:process_method) do
    proc do
      def process
        true
      end
    end
  end

  describe '#call' do
    it { expect(logic_instance).to respond_to(:ctx) }
    it { expect(logic_instance).to respond_to(:semantic) }
    it { expect(logic_instance).to respond_to(:message) }

    it { expect(perform).to be_a(described_class) }
    it { expect(perform.ctx).to eq params }
    it { expect(perform.semantic).to be_nil }
    it { expect(perform.message).to be_nil }

    describe 'call sequence' do
      before do
        allow(logic_instance).to receive(:prepare).and_call_original
        allow(logic_instance).to receive(:process).and_call_original
      end

      it 'calls methods in correct order' do
        perform

        expect(logic_instance).to have_received(:prepare).ordered
        expect(logic_instance).to have_received(:process).ordered
      end
    end
  end

  describe '#failure?' do
    let(:process_method) do
      proc do
        def process
          fail_step(semantic: :some_semantic, message: 'Error message')
        end
      end
    end

    it { expect(perform).to be_failure }
    it { expect(perform).not_to be_success }
    it { expect(perform.semantic).to eq :some_semantic }
    it { expect(perform.message).to eq 'Error message' }

    context 'when step failure' do
      it 'calls block' do
        allow(some_param).to receive(:capitalize)
        failure_handler = ->(instance) { instance.ctx[:some_param].capitalize }

        perform.failure? do |instance|
          failure_handler.call(instance)
        end

        expect(some_param).to have_received(:capitalize)
      end
    end

    context 'when step success' do
      let(:process_method) do
        proc do
          def process
            true
          end
        end
      end

      it 'does not call block' do
        allow(some_param).to receive(:capitalize)
        failure_handler = ->(instance) { instance.ctx[:some_param].capitalize }

        perform.failure? do |instance|
          failure_handler.call(instance)
        end

        expect(some_param).not_to have_received(:capitalize)
      end
    end
  end

  describe '#success?' do
    let(:process_method) do
      proc do
        def process
          pass_step(semantic: :some_semantic, message: 'Success')
        end
      end
    end

    it { expect(perform).to be_success }
    it { expect(perform).not_to be_failure }
    it { expect(perform.semantic).to eq :some_semantic }
    it { expect(perform.message).to eq 'Success' }

    context 'when step success' do
      it 'calls block' do
        allow(some_param).to receive(:capitalize)
        success_handler = ->(instance) { instance.ctx[:some_param].capitalize }

        perform.success? do |instance|
          success_handler.call(instance)
        end

        expect(some_param).to have_received(:capitalize)
      end
    end

    context 'when step failure' do
      let(:process_method) do
        proc do
          def process
            fail_step
          end
        end
      end

      it 'does not call block' do
        allow(some_param).to receive(:capitalize)
        success_handler = ->(instance) { instance.ctx[:some_param].capitalize }

        perform.success? do |instance|
          success_handler.call(instance)
        end

        expect(some_param).not_to have_received(:capitalize)
      end
    end
  end
end
