import { MemoryRouter } from 'react-router';
import { Route, Link } from 'react-router-dom';
import Header from './header';
import Footer from './footer';
import Article from '../routes/article';
import config from '../config';

const Home = () => (
	<div class="page-content">
		<div class="wrapper">
			<div>
				<ul class="post-list">
					{config.articles.map(article => (
						<li>
							<span class="post-meta">{article.created}</span>
							<h2><Link class="post-link" to={`/article/${article.name}`}>{article.name}</Link></h2>
						</li>
					))}
				</ul>
			</div>
		</div>
	</div>
);

const About = () => (
	<div class="page-content">
		<div class="wrapper">
			<div class="post">
				<header class="post-header">
					<h1 class="post-title">About</h1>
				</header>

				<article class="post-content">
					<p><a href="https://github.com/linychuo">github.com/linychuo</a></p>
					<p><a href="https://bitbucket.org/linychuo">bitbucket.org/linychuo</a></p>
				</article>
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
			<Route path="/article/:name" component={Article} />
			<Footer />
		</div>
	</MemoryRouter>
);

export default App;
