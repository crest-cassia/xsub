require 'stringio'

RSpec.describe Xsub::Submitter do

  before(:each) do
    @submitter = Xsub::Submitter.new( Dummy.new )
    @log_dir = "log_test"
    @work_dir = "work_test"
    Dir.glob("*_xsub*.sh").each do |f|
      FileUtils.rm(f)
    end
    $stdout = StringIO.new  # supress stdout
  end

  after(:each) do
    FileUtils.rm_r(@log_dir) if File.directory?(@log_dir)
    FileUtils.rm_r(@work_dir) if File.directory?(@work_dir)
    Dir.glob("*_xsub*.sh").each do |f|
      FileUtils.rm(f)
    end
    $stdout = STDOUT
  end

  describe "#parse_arguments" do

    it "prints definition and exit when -t option is given" do
      #expect(Kernel).to receive(:exit)
      argv = %w(-t)
      expect {
        @submitter.run(argv)
      }.to raise_error SystemExit
      obj = JSON.load($stdout.string)
      s = @submitter.scheduler
      expect( obj["parameters"] ).to eq JSON.load( JSON.dump(s.class::PARAMETERS) )
      expect( obj["template"].join("\n") ).to eq s.class::TEMPLATE.chomp
    end

    it "parses -p PARAM option" do
      argv = %w(-p {"mpi_procs":8,"omp_threads":4,"p1":"foo"} job.sh)
      @submitter.run(argv)
      expected = {"mpi_procs"=>8,"omp_threads"=>4,"p1"=>"foo"}
      expect( @submitter.parameters ).to eq expected
    end

    it "parses -l LOG_DIR option" do
      argv = %w(-l log_test job.sh)
      @submitter.run(argv)
      expect( @submitter.log_dir ).to eq @log_dir
      expect( File.directory?(@log_dir) ).to be_truthy
    end

    it "parses -d WORK_DIR option" do
      argv = %w(-d work_test job.sh)
      @submitter.run(argv)
      expect( @submitter.work_dir ).to eq @work_dir
      expect( File.directory?(@work_dir) ).to be_truthy
    end

    it "parses job_script" do
      argv = %w(-p {"mpi_procs":8} -d work_test -l log_test job.sh)
      @submitter.run(argv)
      expect( @submitter.script ).to eq "job.sh"
    end

    it "raises an error when script is not given" do
      argv = %w(-p {"mpi_procs":8} -d work_test -l log_test)
      expect {
        @submitter.run(argv)
      }.to raise_error "no job script is given"
    end

    it "raises an error when unknown parameter is given" do
      argv = %w(-a foo job.sh)
      expect {
        @submitter.run(argv)
      }.to raise_error OptionParser::InvalidOption
    end
  end

  describe "merge_default_parameters" do

    it "merges default parameters" do
      argv = %w(-p {"mpi_procs":8} job.sh)
      @submitter.run(argv)
      expected = {"mpi_procs" =>8,"omp_threads" =>1,"p1"=>"abc"}
      expect( @submitter.parameters ).to eq expected
    end
  end

  describe "verify parameter format" do

    it "raises an error when unknown parameter is given" do
      argv = %w(-p {"foo":1} job.sh)
      expect {
        @submitter.run(argv)
      }.to raise_error(/unknown parameter is given/)
    end

    it "raises an error when value does not conform to format" do
      argv = %w(-p {"mpi_procs":0} job.sh)
      expect {
        @submitter.run(argv)
      }.to raise_error(/invalid parameter format/)
    end
  end

  describe "Scheduler#validate_parameters" do

    it "calls Scheduler#validate_parameters" do
      expect(@submitter.scheduler).to receive(:validate_parameters) do |arg|
        expect(arg).to eq @submitter.parameters
        {"job_id" => "1234"}
      end
      argv = %w(job.sh)
      @submitter.run(argv)
    end
  end

  describe "prepare parent script" do

    it "creates parent script" do
      argv = %w(job.sh)
      @submitter.run(argv)
      expect( File.exist?("job_xsub.sh") ).to be_truthy
    end

    it "creates parent script with a unique name" do
      argv = %w(job.sh)
      FileUtils.touch "job_xsub.sh"
      @submitter.run(argv)
      expect( File.exist?("job_xsub1.sh") ).to be_truthy
    end

    it "renders template" do
      argv = %w(-p {"mpi_procs":8,"omp_threads":4,"p1":"abc"} -d work_test job.sh)
      @submitter.run(argv)

      rendered = File.read("work_test/job_xsub.sh")
      expected = <<-EOS
mpi_procs:8
omp_threads:4
p1:abc
work_dir:#{Dir.pwd}/work_test
. #{File.expand_path("job.sh")}
    EOS

      expect( rendered ).to eq expected
    end
  end

  describe "Scheduler#submit_job" do

    it "calls Scheduler#submit_job" do
      expect(@submitter.scheduler).to receive(:submit_job) {|arg,_,_,_|
        expect( arg ).to eq File.expand_path("job_xsub.sh")
        {:job_id => "1234"}
      }
      argv = %w(job.sh)
      @submitter.run(argv)
    end
  end
end

