require File.expand_path('../../spec_helper', __FILE__)
require 'commit_hook'

describe CommitHook do

  it "should ignore merge" do
    # 4 commits, one email for each of them, without merge
    run_with_config('spec/fixtures/git-notifier-ignore-merge.yml', 4)
  end

  it "should hook with merge" do
    # 5 commits, one email for each of them, with merge mail
    run_with_config('spec/fixtures/git-notifier-with-merge.yml', 5)
  end

  it "should hook group email by push" do
    # 1 commit for the push, all commits in the one message
    run_with_config('spec/fixtures/git-notifier-group-email-by-push.yml', 1)
  end

  def run_with_config(config, times)
    expect_repository_access

    emailer = mock!.send.times(times).subject
    mock(Emailer).new(anything, anything) { emailer }.times(times)

    mock(CommitHook).info(/Sending mail/)

    any_instance_of(DiffToHtml, :check_handled_commits => lambda { |commits| commits })
    CommitHook.run config, REVISIONS.first, REVISIONS.last, 'refs/heads/master'
  end

  def test_commit_from
    # 1 commit with a from: adress
    expect_repository_access
    emailer = mock!.send.subject
    mock(Emailer).new(anything, hash_including(:from_address => "max@example.com")) { emailer }

    CommitHook.run 'spec/fixtures/git-notifier-group-email-by-push.yml', REVISIONS.first, REVISIONS.last, 'refs/heads/master'
   end

  def expect_repository_access
    mock(Git).log(REVISIONS.first, REVISIONS.last) { IO.read(FIXTURES_PATH + 'git_log') }
    mock(Git).mailing_list_address { 'recipient@test.com' }
    REVISIONS.each do |rev|
      mock(Git).show(rev) { IO.read(FIXTURES_PATH + "git_show_#{rev}") }
    end
  end

  describe :logger do
    it "should be nstance of logger" do
      stub(CommitHook).config { {} }
      CommitHook.logger.should be_kind_of(Logger)
    end
  end

  describe :show_error do
    it "should write error to stderr" do
      mock($stderr).puts("\n").times(2)
      mock($stderr).puts(/GIT\sNOTIFIER\sPROBLEM/).times(2)
      mock($stderr).puts('yes')
      CommitHook.show_error('yes')
    end
  end

  describe :info do
    it "should write to and flush stdout" do
      mock($stdout).puts('msg')
      mock($stdout).flush
      CommitHook.info('msg')
    end
  end

  describe :run do
    it "should report error when no recipients specified" do
      mock(File).exists?(:noconfig) { false }
      mock(Git).mailing_list_address { nil }
      mock(CommitHook).show_error(/recipient/)
      CommitHook.run(:noconfig, :rev1, :rev2, 'master')
    end
  end

end

__END__

 vim: tabstop=2 expandtab shiftwidth=2

