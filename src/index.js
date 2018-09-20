import './style';
import { MemoryRouter } from 'react-router';
import { Route, Link } from 'react-router-dom';
import Header from './components/header';
import Footer from './components/footer';
import Article from './routes/article';
import About from './routes/about';
import config from './config';

const Home = () => (
	<div class="page-content">
		<div class="wrapper">
			<div>
				<ul class="post-list">
					{config.posts.map(it => (
						<li>
							<span class="post-meta">{it.createdDate}</span>
							<h2><Link class="post-link" to={`/post/${it.title}`}>{it.title}</Link></h2>
						</li>
					))}
				</ul>
			</div>
		</div>
	</div>
);

const App = () => (
	<MemoryRouter>
		<div>
			<Header />
			<Route exact path="/" component={Home} />
			<Route path="/about" component={About} />
			<Route path="/post/:name" component={Article} />
			<Footer />
		</div>
	</MemoryRouter>
);

export default App;
