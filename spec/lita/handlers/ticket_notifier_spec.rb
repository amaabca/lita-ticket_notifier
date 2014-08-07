require "spec_helper"
require "json"

describe Lita::Handlers::TicketNotifier, lita_handler: true do
  let(:payload) { File.read(File.join('spec', 'fixtures', 'ticket.json')) }
  let(:request) { OpenStruct.new({ body: OpenStruct.new({ read: payload }) }) }
  let(:teddy) { Lita::User.create(123, name: "Teddy Ruxbin") }

  it { routes_command("ticket notify start").to(:add_ticket_notification) }
  it { routes_command("ticket notify stop").to(:remove_ticket_notification) }
  it { routes_http(:post, "/ticket_notification").to(:ticket_notification) }

  it "defaults to no users" do
    expect(subject.user_names).to eq []
  end

  it "adds notification users" do
    send_command("ticket notify start")
    send_command("ticket notify start", as: teddy)

    expect(subject.user_names).to include(user.name)
    expect(subject.user_names).to include(teddy.name)

    expect(replies.count).to eq(2)
    expect(replies.first).to eq("You will now get notified of ticket updates.")
    expect(replies.last).to eq("You will now get notified of ticket updates.")
  end

  it "removes a notification user" do
    send_command("ticket notify start")
    send_command("ticket notify start", as: teddy)
    send_command("ticket notify stop")

    expect(subject.user_names).to_not include(user.name)
    expect(subject.user_names).to include(teddy.name)

    expect(replies.count).to eq(3)
    expect(replies[0]).to eq("You will now get notified of ticket updates.")
    expect(replies[1]).to eq("You will now get notified of ticket updates.")
    expect(replies[2]).to eq("You will no longer receive ticket update notifications.")
  end

  it "notifies about tickets" do
    send_command("ticket notify start")
    subject.ticket_notification(request, nil)

    expect(replies.last).to eq(subject.message)
  end
end
