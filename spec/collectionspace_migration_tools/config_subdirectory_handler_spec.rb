# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe CollectionspaceMigrationTools::ConfigSubdirectoryHandler do
  let(:base_dir_val) { File.join(Bundler.root, "spec", "support") }
  let(:config) do
    Struct.new(:base_dir, :mapper_dir).new(base_dir_val, mapper_dir_val)
  end
  let(:instance) { described_class.new(config: config, setting: :mapper_dir) }
  let(:result) { instance.call }

  context "with absolute path given" do
    context "when given dir exists" do
      before do
        @path = "#{File.join(Bundler.root, "tmp")}/mappers"
        FileUtils.mkdir(@path)
      end
      after { FileUtils.rm_rf(@path) }

      let(:mapper_dir_val) { @path }

      it "does not change config" do
        result
        expect(config.mapper_dir).to eq(mapper_dir_val)
        expect(Dir.exist?(mapper_dir_val)).to be true
      end
    end

    context "when given dir does not exist" do
      let(:mapper_dir_val) { File.join(Bundler.root, "foo", "bar", "mappers") }

      it "raises error" do
        expect do
          result
        end.to raise_error(CMT::ConfigSubdirectoryHandler::NonExistentDirectorySpecifiedError)
      end
    end
  end

  context "when relative path given" do
    let(:mapper_dir_val) { "~/cs_mig_tools_test" }

    context "when given dir exists" do
      before { FileUtils.mkdir(File.expand_path("~/cs_mig_tools_test")) }
      after { FileUtils.rm_rf(File.expand_path("~/cs_mig_tools_test")) }

      it "updates config to absolute path" do
        result
        expect(config.mapper_dir).to eq(File.expand_path(mapper_dir_val))
        expect(Dir.exist?(File.expand_path(mapper_dir_val))).to be true
      end
    end

    context "when given dir does not exist" do
      it "raises error" do
        expect do
          result
        end.to raise_error(CMT::ConfigSubdirectoryHandler::NonExistentDirectorySpecifiedError)
      end
    end
  end

  context "when subdir given" do
    let(:mapper_dir_val) { "mappers" }

    context "when given dir exists" do
      before do
        @path = File.join(Bundler.root, "spec", "support", "mappers")
        FileUtils.mkdir(@path)
      end
      after { FileUtils.rm_rf(@path) }

      it "updates config to absolute path" do
        result
        expect(config.mapper_dir).to eq(@path)
      end
    end

    context "when given dir does not exist" do
      before { @path = File.join(Bundler.root, "spec", "support", "mappers") }
      after { FileUtils.rm_rf(@path) }
      it "updates config to absolute path and creates directory" do
        result
        expect(config.mapper_dir).to eq(@path)
        expect(Dir.exist?(@path)).to be true
      end
    end
  end
end
