require File.dirname(__FILE__) + '/../../../../../../test/test_helper'

class Wikis::VersionsControllerTest < ActionController::TestCase
  fixtures :pages, :users, :user_participations, :wikis, :groups

  def setup
    Crabgrass::Wiki::HTMLDiff.log_to_stdout = false # set to true for debugging
  end

  def test_version_show
    login_as :orange
    pages(:wiki).add groups(:rainbow), access: :edit
    wiki = pages(:wiki).data

    # create versions
    %w[yellow orange blue yellow red purple].each do |user|
      wiki.update_section! :document, users(user), nil,
        "text from %s for the wiki" % user
    end

    login_as :orange
    wiki.versions.reload

    assert_equal 6, wiki.versions.count
    assert_equal 6, wiki.versions.last.version

    # find versions
    get :show, wiki_id: wiki.id, id: 5
    assert_response :success
    assert_equal 5, assigns(:version).version
    assert_equal 'text from purple for the wiki', assigns(:wiki).body
    assert_equal 'text from red for the wiki', assigns(:version).body
    assert_equal 4, assigns(:former).version
  end

  def test_show_invalid_version
    pages(:wiki).add groups(:rainbow), access: :edit
    wiki = pages(:wiki).data
    wiki.update_section!(:document, users(:purple), 1, "text for the wiki")
    login_as :orange
    # should fail gracefully for non-existant version
    get :show, wiki_id: wiki.id, id: 7
    assert_response :redirect
    assert_redirected_to action: :index
  end

  def test_revert
    login_as :orange
    page = pages(:wiki)
    wiki = page.data
    wiki.update_section!(:document, users(:blue), 1, "version 1")
    wiki.update_section!(:document, users(:yellow), 2, "version 2")
    post :revert, wiki_id: wiki.id, id: 1

    wiki.reload

    assert_redirected_to wiki_versions_path(wiki),
      "revert should redirect to wiki versions list"
    assert_equal "version 1", wiki.body
  end

end
