import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding database...\n');

  // ── Clean existing data ──────────────────────────────────────────────────────
  await prisma.message.deleteMany();
  await prisma.conversationMember.deleteMany();
  await prisma.conversation.deleteMany();
  await prisma.user.deleteMany();
  console.log('🗑️  Cleared existing data');

  const hash = (p: string) => bcrypt.hash(p, 10);

  // ── Create users ─────────────────────────────────────────────────────────────
  const [alice, bob, carol, dave, eve] = await Promise.all([
    prisma.user.create({
      data: {
        username: 'alice',
        email: 'alice@nexora.app',
        password: await hash('password123'),
        name: 'Alice Johnson',
        bio: 'Designer & coffee enthusiast ☕',
      },
    }),
    prisma.user.create({
      data: {
        username: 'bob',
        email: 'bob@nexora.app',
        password: await hash('password123'),
        name: 'Bob Smith',
        bio: 'Backend dev. Loves hiking 🏔️',
      },
    }),
    prisma.user.create({
      data: {
        username: 'carol',
        email: 'carol@nexora.app',
        password: await hash('password123'),
        name: 'Carol White',
        bio: 'Product manager. Dog mom 🐶',
      },
    }),
    prisma.user.create({
      data: {
        username: 'dave',
        email: 'dave@nexora.app',
        password: await hash('password123'),
        name: 'Dave Lee',
        bio: 'Full-stack engineer 💻',
      },
    }),
    prisma.user.create({
      data: {
        username: 'eve',
        email: 'eve@nexora.app',
        password: await hash('password123'),
        name: 'Eve Martinez',
        bio: 'ML researcher & avid reader 📚',
      },
    }),
  ]);
  console.log('👥 Created 5 users: alice, bob, carol, dave, eve  (password: password123)');

  // ── Helper: create a 1-on-1 conversation with messages ──────────────────────
  async function createDirect(
    userA: typeof alice,
    userB: typeof alice,
    messages: { sender: typeof alice; content: string; minsAgo: number }[]
  ) {
    const conv = await prisma.conversation.create({
      data: {
        isGroup: false,
        members: { create: [{ userId: userA.id }, { userId: userB.id }] },
      },
    });

    for (const m of messages) {
      const ts = new Date(Date.now() - m.minsAgo * 60 * 1000);
      await prisma.message.create({
        data: {
          conversationId: conv.id,
          senderId: m.sender.id,
          content: m.content,
          type: 'TEXT',
          status: 'READ',
          createdAt: ts,
          updatedAt: ts,
        },
      });
    }

    // Set updatedAt to time of last message
    const latestTs = new Date(Date.now() - Math.min(...messages.map((m) => m.minsAgo)) * 60 * 1000);
    await prisma.conversation.update({
      where: { id: conv.id },
      data: { updatedAt: latestTs },
    });

    return conv;
  }

  // ── Helper: create a group conversation ─────────────────────────────────────
  async function createGroup(
    name: string,
    members: typeof alice[],
    messages: { sender: typeof alice; content: string; minsAgo: number }[]
  ) {
    const conv = await prisma.conversation.create({
      data: {
        isGroup: true,
        name,
        members: {
          create: members.map((u, i) => ({
            userId: u.id,
            role: i === 0 ? 'ADMIN' : 'MEMBER',
          })),
        },
      },
    });

    for (const m of messages) {
      const ts = new Date(Date.now() - m.minsAgo * 60 * 1000);
      await prisma.message.create({
        data: {
          conversationId: conv.id,
          senderId: m.sender.id,
          content: m.content,
          type: 'TEXT',
          status: 'READ',
          createdAt: ts,
          updatedAt: ts,
        },
      });
    }

    const latestTs = new Date(Date.now() - Math.min(...messages.map((m) => m.minsAgo)) * 60 * 1000);
    await prisma.conversation.update({
      where: { id: conv.id },
      data: { updatedAt: latestTs },
    });

    return conv;
  }

  // ── Seed conversations ───────────────────────────────────────────────────────

  // Alice ↔ Bob
  await createDirect(alice, bob, [
    { sender: alice, content: 'Hey Bob! Did you finish the API review?', minsAgo: 120 },
    { sender: bob, content: 'Almost done! Just a couple of endpoints left.', minsAgo: 115 },
    { sender: alice, content: 'Nice. Let me know when you push the changes 👍', minsAgo: 110 },
    { sender: bob, content: 'Will do. Also the image upload endpoint might need a size limit.', minsAgo: 60 },
    { sender: alice, content: 'Good catch — I set the body limit to 50MB on express.', minsAgo: 55 },
    { sender: bob, content: 'Perfect. Merging now 🚀', minsAgo: 5 },
  ]);

  // Alice ↔ Carol
  await createDirect(alice, carol, [
    { sender: carol, content: 'Alice, the new design mockups look amazing!', minsAgo: 600 },
    { sender: alice, content: 'Thanks! I was going for that glassmorphism vibe 😊', minsAgo: 595 },
    { sender: carol, content: 'Can we schedule a review session tomorrow?', minsAgo: 590 },
    { sender: alice, content: 'Absolutely — 10am works for me!', minsAgo: 585 },
    { sender: carol, content: 'Great, see you then!', minsAgo: 580 },
  ]);

  // Bob ↔ Dave
  await createDirect(bob, dave, [
    { sender: dave, content: 'Bob! Socket.io is dropping connections randomly 😩', minsAgo: 200 },
    { sender: bob, content: 'Sounds like a heartbeat timeout. Try setting pingTimeout to 30000.', minsAgo: 195 },
    { sender: dave, content: 'Oh that fixed it!!! You\'re a legend 🙌', minsAgo: 190 },
    { sender: bob, content: 'Anytime. Happens a lot with websocket proxies.', minsAgo: 185 },
  ]);

  // Eve ↔ Alice
  await createDirect(eve, alice, [
    { sender: eve, content: 'Alice, did you read the new paper on diffusion models?', minsAgo: 1440 },
    { sender: alice, content: 'Not yet! Send me the link?', minsAgo: 1435 },
    { sender: eve, content: 'https://arxiv.org/abs/2305.00000 — it\'s mind-blowing', minsAgo: 1430 },
    { sender: alice, content: 'Bookmarked! Will read this weekend 📚', minsAgo: 1425 },
  ]);

  // Group: Team Nexora
  await createGroup(
    'Team Nexora 🚀',
    [alice, bob, carol, dave, eve],
    [
      { sender: carol, content: 'Morning everyone! Sprint planning at 9am today.', minsAgo: 480 },
      { sender: dave, content: 'On it! I\'ll finish the auth tests before then.', minsAgo: 475 },
      { sender: bob, content: 'Same, just finishing up the socket refactor.', minsAgo: 470 },
      { sender: alice, content: 'I\'ll have the new screens ready to demo 🎨', minsAgo: 465 },
      { sender: eve, content: 'Can we also discuss the ML feature in backlog?', minsAgo: 460 },
      { sender: carol, content: 'Yes! Let\'s add it to the agenda.', minsAgo: 455 },
      { sender: dave, content: 'All tests passing now btw 🟢', minsAgo: 30 },
      { sender: alice, content: 'Amazing! Let\'s ship this 🎉', minsAgo: 25 },
    ]
  );

  // Group: Design Squad
  await createGroup(
    'Design Squad 🎨',
    [alice, carol, eve],
    [
      { sender: alice, content: 'Check out the new color palette I put together!', minsAgo: 300 },
      { sender: carol, content: 'Love the gradient on the primary button 😍', minsAgo: 295 },
      { sender: eve, content: 'Can we try a slightly darker shade for dark mode?', minsAgo: 290 },
      { sender: alice, content: 'Good idea — I\'ll push an update tonight.', minsAgo: 285 },
      { sender: carol, content: 'The home screen mock looks premium!', minsAgo: 10 },
    ]
  );

  console.log('💬 Created 4 direct conversations and 2 group chats');
  console.log('\n✅ Seed complete!\n');
  console.log('📧 Login with any of these accounts (password: password123):');
  console.log('   alice@nexora.app');
  console.log('   bob@nexora.app');
  console.log('   carol@nexora.app');
  console.log('   dave@nexora.app');
  console.log('   eve@nexora.app');
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
