require_relative "../config/boot.rb"

module App
  class API < Grape::API
    version 'v1', using: :path
    format :json

    helpers do
      def token
        request.cookies[App.session_id]
      end

      def session
        Session.restore(token)
      end

      def current_user
        return unless session
        @current_user ||= User.find(session.body[:user_id])
      end

      def current_room
        Room.find_by(id: params[:room_id])
      end

      def current_citizen
        current_room.citizens.find_by(user: current_user)
      end

      def login_required
        error! "Login first.", 401 unless current_user
      end

      def send_global_event(event, params = {})
        Channel.global_send({
          event: event
        }.merge(params))
      end
    end

    get "/" do
      current_user
    end

    namespace :cheat do
      before { error! "xxx", 404 if App.env != :test }

      resource :login do
        route_param :user_id do
          get do
            session = ::Session.create(body: {
              user_id: params[:user_id]
            })
            cookies[App.session_id] = {
              value: session.unique_id,
              path: "/",
              httponly: true
            }
            User.find(params[:user_id])
          end
        end
      end
    end

    resource :rooms do
      get do
        {
          active: Room.not_archived.eager_load(:citizens, citizens: [:user]).order(id: :desc).map {|r|
            r.attributes.merge(
              citizens: r.citizens,
              users: r.citizens.map(&:user),
              isReady: r.ready?,
            )
          },
          archived: Room.archived.order(id: :desc).includes(:citizens).map {|r|
            r.attributes.merge(
              member_count: r.citizens.size
            )
          },
        }
      end

      desc "Create room"
      post do
        login_required
        room = Room.create!(params.slice(:name).merge(created_by: current_user).to_hash)
        send_global_event("rooms:created")
        room
      end

      route_param :room_id do
        before do
          error! "not found", 404 unless current_room
        end

        get do
          current_room.to_json_hash.merge(
            personalInfo: current_room.current_information_for(current_citizen),
            voteRequired: current_citizen.try(:action_required?),
            votedTo: current_citizen.try(:current_vote).try(:to).try(:user),
          )
        end

        get :ready do
          current_room.ready?
        end

        get :roles do
          # 不使用
          current_room.roles
        end

        delete do
          if current_room.created_by != current_room
            error! "You are not created this room", 400
          end
          current_room.destroy
        end

        put :start do
          current_room.start!
        end

        resource :members do
          get do
            current_room.members(with_role: current_citizen.nil?)
          end

          post do
            login_required
            error! "This room already started." unless current_room.before_start?

            response = current_room.join(current_user)

            current_room.send_room_event(event: "updated:members", user: current_user, members: current_room.members)
            send_global_event("rooms:members:updated", roomId: current_room.id)
            response
          end

          delete do
            login_required
            error! "This room already started." unless current_room.before_start?

            response = current_room.leave(current_user)

            current_room.send_room_event(event: "updated:members", user: current_user, members: current_room.members)
            send_global_event("rooms:members:updated", roomId: current_room.id)
            response
          end
        end

        resource :votes do
          route_param :citizen_id do
            put do
              login_required
              begin
                current_room.with_lock do
                  current_citizen.vote_to(current_room.citizens.find(params[:citizen_id]))
                  current_citizen.current_vote
                end
              rescue ActiveRecord::RecordInvalid => e
                error! e.record.errors.full_messages, 400
              end
            end
          end
        end

        get :channel do
          trans = Transmitter.new(room: current_room, user: current_user)
          trans.channel_token
        end

        get :archive do
          env['api.format'] = :txt
          content_type 'text/plain'
          archive = App.root.join("js/archive/#{params[:room_id]}.html")
          error! "Invalid archive request", 400 unless archive.to_s.match(App.root.to_s)
          error! "Not found archive", 404 unless archive.exist?
          header "X-Accel-Redirect", "/archive/#{archive.basename}"
        end

        get :messages do
          # for SSR
          # current_room.messages
        end

        post :messages do
          error! "Empty message",400 if params[:message].blank?

          if current_room.current_scene.frozen_chat?
            error! "Chat is frozen", 304
          else
            trans = Transmitter.new(room: current_room, user: current_user)
            trans << params[:message].strip
          end
        end

        get :scene do
        end
      end
    end

    resource :users do
      get "me" do
        current_user || {}
      end
    end
  end
end


