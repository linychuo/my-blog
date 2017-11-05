import { Component } from 'preact';
import { Link } from 'preact-router/match';
import config from '../config';

export default class Home extends Component {
    getHref = (name) => `/article/${name}`;

    render() {
		return (
			<div class="page-content">
				<div class="wrapper">
        			<div>
        				<ul class="post-list">
        				{config.articles.map(article => 
    					<li>
    						<span class="post-meta">{article.created}</span>
    						<h2><Link class="post-link" href={this.getHref(article.name)}>{article.name}</Link></h2>
    					</li>
        				)}
        				</ul>
        				<p>subscribe <Link href="/feed.xml">via RSS</Link></p>
        			</div>
        		</div>
			</div>
		);
	}
}