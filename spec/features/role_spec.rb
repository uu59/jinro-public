require "spec_helper"

describe "役職の機能" do
  include ApiSupport

  let!(:room) { create_room(user_count: 9) }
  let(:wolf1) { room.citizens.find_by(role_id: Role[:wolf].id) }
  let(:wolf2) { room.citizens.where(role_id: Role[:wolf].id).where.not(id: wolf1.id).first }
  let(:uranai) { room.citizens.find_by(role_id: Role[:uranai].id) }
  let(:human) { room.citizens.where(role_id: Role[:human].id).where.not(user: User.scapegoat).first }
  let(:guard) { room.citizens.find_by(role_id: Role[:guard].id) }
  let(:reinou) { room.citizens.find_by(role_id: Role[:reinou].id) }
  let(:lovers1) { room.citizens.find_by(role_id: Role[:lovers].id) }
  let(:lovers2) { room.citizens.where(role_id: Role[:lovers].id).where.not(id: lovers1.id).first }
  let(:fullmooner) { room.citizens.find_by(role_id: Role[:fullmooner].id) }
  let(:scapegoat) { room.citizens.find_by(user: User.scapegoat) }

  before { room.start!(role_pattern: "TEST") }
  before do
    # 面倒なので生け贄は村人にする
    r = scapegoat.role_id
    if r != Role[:human].id
      swap_target = room.citizens.find_by(role_id: Role[:human].id)
      scapegoat.update_attribute(:role_id, Role[:human].id)
      swap_target.update_attribute(:role_id, r)
    end
  end

  describe "夜1" do
    let(:user) { citizen.user}

    before do
      login(user)
    end

    describe "村人" do
      let(:citizen) { human }

      it "メッセージ" do
        get("/v1/rooms/#{room.id}")
        expect(last_json[:personalInfo]).to eq "夜です。あなたは「村人」です。"
        expect(last_json[:voteRequired]).to eq false
      end
    end

    describe "人狼1" do
      let(:citizen) { wolf1 }

      it "メッセージ" do
        get("/v1/rooms/#{room.id}")
        expect(last_json[:personalInfo]).to eq "夜です。あなたは「人狼」です。ターゲットを選んでください。人狼が複数居る場合は、最初に投票されたターゲットを襲います。"
        expect(last_json[:voteRequired]).to eq true
      end
    end

    describe "人狼2" do
      let(:citizen) { wolf2 }

      it "片方の人狼が投票すると自分もその相手に投票したことになる" do
        get("/v1/rooms/#{room.id}")
        expect(last_json[:votedTo]).to eq nil
        wolf1.vote_to scapegoat
        get("/v1/rooms/#{room.id}")
        expect(last_json[:votedTo][:id]).to eq scapegoat.user.id
      end
    end

    describe "占い" do
      let(:citizen) { uranai }

      it "メッセージ" do
        get("/v1/rooms/#{room.id}")
        expect(last_json[:personalInfo]).to eq "夜です。あなたは「占い師」です。昼になると、夜のあいだに選んだ相手が「人狼」か「人狼じゃない」かがわかります。"
        expect(last_json[:voteRequired]).to eq true
      end
    end


    describe "霊能" do
      let(:citizen) { reinou }

      it "メッセージ" do
        get("/v1/rooms/#{room.id}")
        expect(last_json[:personalInfo]).to eq "夜です。あなたは「霊能者」です。夜になると、昼に投票で処刑された人が「人狼」か「人狼じゃない」かがわかります。（※最初の夜は何もわかりません）"
        expect(last_json[:voteRequired]).to eq false
      end
    end

    describe "狂人" do
      let(:citizen) { fullmooner }

      it "メッセージ" do
        get("/v1/rooms/#{room.id}")
        expect(last_json[:personalInfo]).to eq "夜です。あなたは「狂人」です。村人と同じく特殊な能力はありませんが、人狼陣営に属しています。"
        expect(last_json[:voteRequired]).to eq false
      end
    end

    describe "騎士" do
      let(:citizen) { guard }

      it "メッセージ" do
        get("/v1/rooms/#{room.id}")
        expect(last_json[:personalInfo]).to eq "夜です。あなたは「騎士」です。守護したい相手を選んでください。守護した人が人狼に襲われた場合、その人は死なずに夜を越せます。（※最初の夜は何もできません）"
        expect(last_json[:voteRequired]).to eq false
      end
    end

    describe "共有1" do
      let(:citizen) { lovers1 }

      it "メッセージ" do
        get("/v1/rooms/#{room.id}")
        expect(last_json[:personalInfo]).to eq "夜です。あなたは「共有者」です。他の共有者は #{lovers2.name} です。夜の間に共有者同士で話し合えます。"
        expect(last_json[:voteRequired]).to eq false
      end
    end

    describe "共有2" do
      let(:citizen) { lovers2 }

      it "メッセージ" do
        get("/v1/rooms/#{room.id}")
        expect(last_json[:personalInfo]).to eq "夜です。あなたは「共有者」です。他の共有者は #{lovers1.name} です。夜の間に共有者同士で話し合えます。"
        expect(last_json[:voteRequired]).to eq false
      end
    end

    describe "昼1" do
      before do
        wolf1.vote_to scapegoat
        uranai.vote_to scapegoat
        SceneChange.new.perform(room.id, room.current_scene.id)
      end

      describe "村人" do
        let(:citizen) { human }

        it "メッセージ" do
          get("/v1/rooms/#{room.id}")
          expect(last_json[:personalInfo]).to eq "昼です。あなたは「村人」です。"
          expect(last_json[:voteRequired]).to eq true
        end
      end

      describe "占い" do
        let(:citizen) { uranai }

        it "メッセージ" do
          get("/v1/rooms/#{room.id}")
          expect(last_json[:personalInfo]).to eq "昼です。あなたは「占い師」です。生け贄 は人狼ではありませんでした"
          expect(last_json[:voteRequired]).to eq true
        end
      end

      describe "夜2（村人が処刑）" do
        before do
          room.citizens.alived.each do |c|
            next if c == human
            c.vote_to human
          end
          human.vote_to wolf1
          SceneChange.new.perform(room.id, room.current_scene.id)
        end

        describe "霊能" do
          let(:citizen) { reinou }

          it "処刑された人の結果（not人狼）が出る" do
            get("/v1/rooms/#{room.id}")
            expect(last_json[:personalInfo]).to include("#{human.name} は 人狼ではありませんでした")
          end
        end

        describe "騎士" do
          let(:citizen) { guard }

          it "投票必須" do
            get("/v1/rooms/#{room.id}")
            expect(last_json[:voteRequired]).to eq true
          end
        end

        describe "昼2（狂人が襲撃されるが騎士がガード）" do
          before do
            guard.vote_to fullmooner
            wolf1.vote_to fullmooner
            uranai.vote_to fullmooner
            SceneChange.new.perform(room.id, room.current_scene.id)
          end

          describe "狂人" do
            let(:citizen) { fullmooner }

            it "生存" do
              get("/v1/rooms/#{room.id}")
              me = last_json[:citizens].find{|c| c[:user][:id] == fullmooner.user.id}
              expect(me[:alive]).to eq true
            end
          end
        end

        describe "昼2（狂人が襲撃される）" do
          before do
            guard.vote_to wolf1
            wolf1.vote_to fullmooner
            uranai.vote_to fullmooner
            SceneChange.new.perform(room.id, room.current_scene.id)
          end

          describe "狂人" do
            let(:citizen) { fullmooner }

            it "死亡" do
              get("/v1/rooms/#{room.id}")
              me = last_json[:citizens].find{|c| c[:user][:id] == fullmooner.user.id}
              expect(me[:alive]).to eq false
            end
          end

          describe "夜3（占いが処刑）" do
            before do
              room.citizens.alived.each do |c|
                next if c == uranai
                c.vote_to uranai
              end
              uranai.vote_to wolf1
              SceneChange.new.perform(room.id, room.current_scene.id)
            end

            describe "昼3（騎士が襲撃されたあと）" do
              before do
                wolf1.vote_to guard
                guard.vote_to wolf1
                SceneChange.new.perform(room.id, room.current_scene.id)
              end

              describe "夜4（霊能が処刑）" do
                before do
                  room.citizens.alived.each do |c|
                    next if c == reinou
                    c.vote_to reinou
                  end
                  reinou.vote_to wolf1
                end

                describe "人狼勝利" do
                  let(:citizen) { wolf1 }

                  it do
                    expect(room.finished?).to eq true
                    expect(room.winner_side).to eq "人狼"
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
