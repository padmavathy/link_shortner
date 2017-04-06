require 'socket'

class LinksController < ApplicationController
  before_action :set_link, only: [:show, :destroy]
  before_filter :authenticate_user!, only: [:new,:create,:destroy,:go]

  def index
    @links = Link.all
    @ip_address = Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }.ip_address
  end

  def show
    @link = Link.find_by(id: params[:id])
    respond_to do |format|
      format.html
      format.json { render :show, status: 200, location: @link, users: [@link.users] }
    end
  end

  def new
    @link = Link.new
  end

  def go
    link = Link.find_by(shortened_url: params["short_url"])
    click = Click.where(link: link.id).where(user_id: current_user.id).last
    if click
      click.count += 1
      click.save
    else
      Click.create(link_id: link.id, user_id: current_user.id,count: 1)
    end
    redirect_to link.given_url
  end

  def create
    @link = Link.new(link_params)
    unless link_params["given_url"].empty?
      url = @link.shorten(link_params["given_url"])
      @link.given_url = link_params["given_url"]
      @link.shortened_url = url
    end
    respond_to do |format|
      if @link.save
        @link.users << current_user
        format.html { redirect_to @link, notice: 'Link was successfully created.' }
        format.json { render :show, status: :created, location: @link }
      else
        format.html { render :new }
        format.json { render json: @link.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @link.destroy
    respond_to do |format|
      format.html { redirect_to links_url, notice: 'Link was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_link
      @link = Link.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def link_params
      params.require(:link).permit(:given_url)
    end
end
