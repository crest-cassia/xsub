RSpec.describe Xsub::Submitter do

  class Dummy < Xsub::Scheduler

    TEMPLATE = <<-EOS
    mpi_procs:<%= mpi_procs %>
    omp_threads:<%= omp_threads %>
    p1:<%= p1 %>
    . <%= job_file %>
    EOS

    PARAMETERS = {
      "mpi_procs" => {
        description: "MPI process",
        default: 1,
        format: '^[1-9]\d*$'},
      "omp_threads" => {
        description: "OMP threads",
        default: 1,
        format: '^[1-9]\d*$'},
      "p1" => {
        description: "param1",
        default: "abc",
        format: ''}
    }

    def submit_job(script_path)
    end
  end

  before(:each) do
    @submitter = Xsub::Submitter.new( Dummy )
  end

  describe "#parse_arguments" do

    before(:each) do
      @log_dir = "log_test"
      @work_dir = "work_test"
    end

    after(:each) do
      FileUtils.rm_r(@log_dir) if File.directory?(@log_dir)
      FileUtils.rm_r(@work_dir) if File.directory?(@work_dir)
    end

    it "parses -p PARAM option" do
      argv = %w(-p {"mpi_procs":8,"omp_threads":4} job.sh)
      @submitter.send(:parse_arguments, argv)
      expected = {"mpi_procs" => 8, "omp_threads" => 4}
      expect( @submitter.parameters ).to eq expected
    end

    it "parses -l LOG_DIR option" do
      argv = %w(-l log_test job.sh)
      @submitter.send(:parse_arguments, argv)
      expect( @submitter.log_dir ).to eq @log_dir
      expect( File.directory?(@log_dir) ).to be_truthy
    end

    it "parses -d WORK_DIR option" do
      argv = %w(-d work_test job.sh)
      @submitter.send(:parse_arguments, argv)
      expect( @submitter.work_dir ).to eq @work_dir
      expect( File.directory?(@work_dir) ).to be_truthy
    end

    it "parses job_script" do
      argv = %w(-p {"mpi_procs":8,"omp_threads":4} -d work_test -l log_test job.sh)
      @submitter.send(:parse_arguments, argv)
      expect( @submitter.script ).to eq "job.sh"
    end

    it "raises an error when script is not given" do
      argv = %w(-p {"mpi_procs":8,"omp_threads":4} -d work_test -l log_test)
      expect {
        @submitter.send(:parse_arguments, argv)
      }.to raise_error "no job script is given"
    end

    it "raises an error when unknown parameter is given" do
      argv = %w(-a foo job.sh)
      expect {
        @submitter.send(:parse_arguments, argv)
      }.to raise_error OptionParser::InvalidOption
    end
  end
end

